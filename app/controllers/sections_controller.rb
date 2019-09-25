class SectionsController < ApplicationController
  before_action :ensure_feature_enabled!

  def my_sections_json
    sections = authorized_sections { current_educator.sections }
    sections_json = sections.as_json({
      only: [:id, :room_number, :schedule, :section_number, :term_local_id],
      include: {
        course: {
          only: [:id, :course_number, :course_description]
        },
        educators: {
          only: [:id, :full_name, :email]
        }
      }
    })
    render json: {
      sections: sections_json
    }
  end

  def section_json
    current_section = authorized_section(params[:id])
    students = authorized { current_section.students.active } # extra layer while transitioning K8 to use sections

    students_json = serialize_students(students.map(&:id), current_section)
    section = serialize_section(current_section)

    # limit navigator to current school year
    district_school_year = Section.to_district_school_year(SchoolYear.to_school_year(Time.now))

    sections_for_navigator = current_educator.allowed_sections.includes(:course).where(district_school_year: district_school_year)
    sections_json = sections_for_navigator.as_json({
      only: [:id, :section_number, :term_local_id],
      methods: [:course_description]
    })

    render json: {
      students: students_json,
      section: section,
      sections: sections_json
    }
  end

  private
  def ensure_feature_enabled!
    raise Exceptions::EducatorNotAuthorized unless PerDistrict.new.enabled_sections?
  end

  def authorized_sections(&block)
    return_value = block.call
    return_value.select do |section|
      authorizer.is_authorized_for_section?(section)
    end
  end

  def authorized_section(section_id)
    section = Section.find(params[:id])
    raise Exceptions::EducatorNotAuthorized unless authorizer.is_authorized_for_section?(section)
    section
  end

  # Include grade for section as well
  def serialize_students(student_ids, section)
    students = Student
      .active
      .where(id: student_ids)
      .includes(:student_section_assignments)

    students.map do |student|
      grade_numeric = student.student_section_assignments.find_by_section_id(section.id).grade_numeric
      student.as_json(methods: [
        :has_photo,
        :event_notes_without_restricted,
        :most_recent_school_year_discipline_incidents_count,
        :most_recent_school_year_absences_count,
        :most_recent_school_year_tardies_count
      ]).merge({
        grade_numeric: grade_numeric
      })
    end
  end

  def serialize_section(section)
    section.as_json(methods: [:course_number, :course_description])
  end
end
