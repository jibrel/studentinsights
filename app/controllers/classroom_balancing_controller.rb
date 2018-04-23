class ClassroomBalancingController < ApplicationController
  # This entire feature is Somerville-specific
  before_action :ensure_somerville_only!

  # The schools and grade levels that this educator would work with.
  # This works by suggesting anything grade levels or schools they have
  # access to now, and then finding the intersection between that and
  # what we should balance
  def available_grade_levels_json
    students = authorized { Student.all }

    schools_for_current_students = students.map(&:school).uniq
    schools_to_balance = School.where(school_type: ['ESMS', 'ES', 'MS'])
    schools = schools_for_current_students & schools_to_balance
    schools_json = schools.as_json(only: [:id, :school_type, :name, :local_id])

    grade_levels_to_balance = [
      'KF',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8'
    ]
    grade_levels_for_current_students = students.map(&:grade).uniq
    grade_levels_for_students_next_year = grade_levels_for_current_students.map {|level| GradeLevels.new.next(level) }
    grade_levels_next_year = grade_levels_for_students_next_year & grade_levels_to_balance

    render json: {
      schools: schools_json,
      grade_levels_next_year: grade_levels_next_year
    }
  end

  def students_for_grade_level_next_year_json
    school_id = params[:school_id]
    grade_level_next_year = params[:grade_level_next_year]
    grade_level_for_current_students = GradeLevels.new.previous(grade_level_next_year)

    # This uses a different authorization scheme for accessing students than
    # elsewhere in the app.  It's intentionally more permissive.
    students = Student.where({
      school_id: school_id,
      grade: grade_level_for_current_students
    })
    students_json = students.as_json

    school = School.find(school_id)
    educator_names_json = (school.educator_names_for_services + Service.provider_names).uniq.compact
    render json: {
      students: students_json,
      educator_names: educator_names_json,
      current_educator_name: current_educator.full_name
    }
  end

  # The data for a particular instance of doing classroom balancing.
  #
  # Authorization is handled differently than normal student-level authorization.
  # Users are only authorized to load records they have created themselves.
  # But, within those records, there may be data about students that they
  # don't usually have access to (they can see all students for their grade
  # in a way they normally might not be able to).
  def classrooms_for_grade_json
    balance_id = params[:balance_id]
    classrooms_for_grade = ClassroomsForGrade.find({
      balance_id: balance_id,
      created_by_educator_id: current_educator.id
    })
    classrooms_for_grade_json = classrooms_for_grade.as_json

    render json: {
      classrooms_for_grade: classrooms_for_grade_json
    }
  end

  # For saving progress on classroom balancing.
  # This is a POST (behaves like an idempotent PUT).
  def update_classrooms_for_grade
    balance_id = params[:balance_id]
    classrooms_for_grade = ClassroomsForGrade.find({
      balance_id: balance_id,
      created_by_educator_id: current_educator.id
    })

    attrs = params.permit(:school_id, :grade_level_next_year, :json)
    classrooms_for_grade.update!(attrs)
    classrooms_for_grade_json = classrooms_for_grade.as_json

    render json: {
      classrooms_for_grade: classrooms_for_grade_json
    }
  end

  private
  def ensure_somerville_only!
    district_key = PerDistrict.new.district_key
    raise Exceptions::EducatorNotAuthorized unless district_key == PerDistrict::SOMERVILLE
  end
end
