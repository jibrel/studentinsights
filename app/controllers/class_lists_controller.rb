# typed: true
class ClassListsController < ApplicationController
  before_action :ensure_feature_enabled_for_district!

  # For showing the list of all workspaces that the user can read
  def workspaces_json
    params.permit(:include_historical)
    params.permit(:time_now)
    include_historical = params.fetch(:include_historical, false)
    time_now = time_now_or_param(params[:time_now])
    query_options = include_historical ? {} : { created_after: SchoolYear.first_day_of_school_for_time(time_now) }
    workspaces = queries.all_authorized_workspaces(query_options)

    workspaces_json = workspaces.map do |workspace|
      {
        workspace_id: workspace.workspace_id,
        revisions_count: workspace.revisions_count,
        class_list: workspace.class_list.as_json({
          only: [
            :id,
            :workspace_id,
            :grade_level_next_year,
            :list_type_text,
            :created_at,
            :updated_at,
            :submitted
          ],
          include: {
            created_by_teacher_educator: {
              only: [:id, :email, :full_name]
            },
            revised_by_principal_educator: {
              only: [:id, :email, :full_name]
            },
            school: {
              only: [:id, :local_id, :name]
            }
          }
        })
      }
    end

    render json: {
      include_historical: include_historical,
      workspaces: workspaces_json
    }
  end

  # For getting access to class list data after the year has passed,
  # until we rework the authorization to work at all times of the year.
  def text
    raise Exceptions::EducatorNotAuthorized unless is_authorization_override_enabled?

    workspace_id = params.require(:workspace_id)
    class_list = ClassList.latest_class_list_for_workspace(workspace_id)
    text = ClassListText.new(class_list).dangerously_render_as_text
    render plain: text
  end

  # Suggest the schools and grade levels that this educator will want to create.
  # This isn't an authorization gate, more a helpful UI suggestion than anything else.
  def available_grade_levels_json
    params.require(:workspace_id)

    # schools
    school_ids = queries.supported_schools.map(&:id).select do |school_id|
      queries.is_authorized_for_school_id?(school_id)
    end
    schools_json = School.find(school_ids).as_json(only: [:id, :name])

    # grade levels (include if any of their schools would allow it)
    grade_levels_next_year = queries.supported_grade_levels_next_year.select do |grade_level_next_year|
      grade_level_now = GradeLevels.new.previous(grade_level_next_year)
      school_ids.any? {|school_id| queries.is_authorized_for_grade_level_now?(school_id, grade_level_now) }
    end

    render json: {
      schools: schools_json,
      grade_levels_next_year: grade_levels_next_year
    }
  end

  # Returns a list of students for the classroom list creator, looking at
  # a particular school and grade level.  Includes data needed for inline
  # profile, except for notes and services (see #profile_json).
  #
  # Authorized here is different than normal.
  def students_for_grade_level_next_year_json
    params.require(:workspace_id)
    params.require(:school_id)
    params.require(:grade_level_next_year)
    school_id = params[:school_id].to_i
    grade_level_next_year = params[:grade_level_next_year]

    # Check authorization by grade level, differently than normal.
    students = queries.authorized_students_for_next_year(school_id, grade_level_next_year)
    students_json = ClassListQueries.students_as_json(students)

    # educator names
    educators_json = Educator.where(school_id: school_id).as_json(only: [:id, :full_name])

    render json: {
      students: students_json,
      educators: educators_json,
      current_educator_id: current_educator.id
    }
  end

  # The data for a particular class list creator `workspace_id`.
  # Users are only authorized to load records they have created themselves.
  def class_list_json
    params.require(:workspace_id)
    workspace_id = params[:workspace_id]
    class_list = queries.read_authorized_class_list(workspace_id)
    raise Exceptions::EducatorNotAuthorized if class_list.nil?

    is_editable = queries.is_authorized_for_writes?(workspace_id)
    class_list_json = serialize_class_list(class_list)
    render json: {
      class_list: class_list_json,
      is_editable: is_editable
    }
  end

  # For saving progress on creating class lists.
  # This is a POST and we store all updates.
  def teacher_updated_class_list_json
    params.require(:workspace_id)
    params.require(:school_id)
    params.require(:grade_level_next_year)
    params.require(:list_type_text)
    params.require(:json)
    params.require(:submitted)
    workspace_id = params[:workspace_id]
    school_id = params[:school_id].to_i
    grade_level_next_year = params[:grade_level_next_year]
    list_type_text = params[:list_type_text]
    json = params[:json]
    submitted = ActiveModel::Type::Boolean.new.cast(params[:submitted])

    # Check that they are authorized for grade level
    grade_level_now = GradeLevels.new.previous(grade_level_next_year)
    raise Exceptions::EducatorNotAuthorized unless queries.is_authorized_for_grade_level_now?(school_id, grade_level_now)

    # Check that they are authorized to write to this particular workspace (eg, not submitted yet).
    raise Exceptions::EducatorNotAuthorized unless queries.is_authorized_for_writes?(workspace_id)

    # Write a new record
    class_list = ClassList.create!({
      workspace_id: workspace_id,
      created_by_teacher_educator_id: current_educator.id,
      school_id: school_id,
      grade_level_next_year: grade_level_next_year,
      list_type_text: list_type_text,
      submitted: submitted,
      json: json # left opaque for UI to iterate
    })
    class_list_json = serialize_class_list(class_list)
    render json: {
      class_list: class_list_json
    }
  end

  # This is a POST for storing all principal revisions.
  def principal_revised_class_list_json
    params.require(:workspace_id)
    params.require(:principal_revisions_json)
    workspace_id = params[:workspace_id]
    principal_revisions_json = params[:principal_revisions_json]

    # The class list must be submitted already
    latest_class_list = ClassList.latest_class_list_for_workspace(workspace_id)
    raise Exceptions::EducatorNotAuthorized unless latest_class_list.submitted?

    # They must be authorized to read it
    grade_level_now = GradeLevels.new.previous(latest_class_list.grade_level_next_year)
    raise Exceptions::EducatorNotAuthorized unless queries.is_authorized_for_grade_level_now?(latest_class_list.school_id, grade_level_now)

    # They must be authorized to revise it
    raise Exceptions::EducatorNotAuthorized unless queries.is_authorized_to_revise?(latest_class_list)

    # Write a new record
    class_list = latest_class_list.dup
    class_list.update!({
      principal_revisions_json: principal_revisions_json,
      revised_by_principal_educator_id: current_educator.id
    })
    render json: {
      class_list: serialize_class_list(class_list)
    }
  end

  # Shows student profile information beyond what's used in the class list creating
  # directly.  Authorization is checked differently here.
  def profile_json
    params.require(:workspace_id)
    params.require(:student_id)
    params.require(:limit)
    params.permit(:time_now)
    workspace_id = params[:workspace_id]
    student_id = params[:student_id].to_i

    # Check that the educator is authorized using class lists rules
    student = ensure_valid_student_for_class_list!(student_id, workspace_id)

    # Load feed cards just for this student
    time_now = time_now_or_param(params[:time_now])
    limit = params[:limit].to_i
    feed = Feed.new([student])
    feed_cards = feed.all_cards(time_now, limit)

    render json: {
      feed_cards: feed_cards
    }
  end

  # Shows student photo.  Authorization is checked differently here.
  def student_photo
    params.require(:workspace_id)
    params.require(:student_id)

    # check valid
    student = ensure_valid_student_for_class_list!(params[:student_id], params[:workspace_id])
    send_params = student_photo_sender.send_params(student)
    if send_params.nil?
      return render json: { error: 'no photo' }, status: 404
    end

    bytes, options = send_params
    send_data bytes, options
  end

  private
  def queries
    @class_list_queries = ClassListQueries.new(current_educator)
  end

  # For individual student data, we have to use a separate
  # system than the standard permission system to allow
  # grade-level access.
  #
  # Authorization is checked differently here, and is more permissive than the
  # standard approach but with log trails to see how these queries fit within the class list
  # creating process.
  def ensure_valid_student_for_class_list!(student_id, workspace_id)
    # Check that the educator is authorized to see the grade and school for this student
    student = Student.find(student_id)
    raise Exceptions::EducatorNotAuthorized unless queries.is_authorized_for_grade_level_now?(student.school_id, student.grade)

    # Check that they gave a valid `workspace_id` and that it matches
    # the school and grade level for the student they're asking about.
    class_list = queries.read_authorized_class_list(workspace_id)
    raise Exceptions::EducatorNotAuthorized if class_list.nil?
    raise Exceptions::EducatorNotAuthorized if class_list.school_id != student.school_id
    raise Exceptions::EducatorNotAuthorized if class_list.grade_level_next_year != GradeLevels.new.next(student.grade)

    student
  end

  def educator_names(school_id)
    school = School.find(school_id)
    [
      school.educator_names_for_services,
      Service.provider_names
    ].flatten.uniq.compact
  end

  def serialize_class_list(class_list)
    class_list.as_json(only: [
      :workspace_id,
      :created_by_teacher_educator_id,
      :school_id,
      :grade_level_next_year,
      :list_type_text,
      :submitted,
      :json,
      :principal_revisions_json,
      :revised_by_principal_educator_id
    ])
  end

  # Use time from value or fall back to Time.now
  def time_now_or_param(params_time_now)
    if params_time_now.present?
      Time.at(params_time_now.to_i)
    else
      Time.now
    end
  end

  def is_authorization_override_enabled?
    current_educator.labels.include?('enable_class_lists_override')
  end

  def ensure_feature_enabled_for_district!
    is_enabled = PerDistrict.new.enabled_class_lists?
    raise Exceptions::EducatorNotAuthorized if !is_enabled && !is_authorization_override_enabled?
  end

  def student_photo_sender
    @student_photo_sender ||= StudentPhotoSender.new(MockAwsS3.create_real_or_mock)
  end
end
