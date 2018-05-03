class ClassroomBalancing
  # This is authorization-aware, and checks authorization for the grade level
  # in a different, more permissive way than normal.
  def query_for_authorized_students(educator, school_id, grade_level_next_year)
    grade_level = GradeLevels.new.previous(grade_level_next_year)
    return [] unless is_authorized_for_grade_level?(educator, school_id, grade_level)

    # Query for those students (outside normal authorization rules)
    Student.active.where({
      school_id: school_id,
      grade: grade_level
    })
  end

  # This is authorization-aware, and it also only lets educators read their own writes.
  def query_for_authorized_balancing(educator, balance_id)
    # Read only most recent own write
    balancings = ClassroomsForGrade
      .order(created_at: :desc)
      .limit(1)
      .where({
        balance_id: balance_id,
        created_by_educator_id: educator.id
      })
    return nil unless balancings.size == 1

    # Check that educator is authorized for that grade level
    balancing = balancings.first
    grade_level = GradeLevels.new.previous(balancing.grade_level_next_year)
    return nil unless is_authorized_for_grade_level?(educator, balancing.school_id, grade_level)

    balancing
  end

  # This is intended only for use in this controller, and allows more people
  # "grade level access" than the standard authorization rules.  It's based off
  # code in `authorizer#is_authorized_for_student?` but is different and more permissive.
  def is_authorized_for_grade_level?(educator, school_id, grade_level)
    return false unless is_authorized_for_school_id?(educator, school_id)
    return true if educator.districtwide_access?
    return true if educator.schoolwide_access?
    return true if educator.admin?
    return true if educator.has_access_to_grade_levels? && grade_level.in?(educator.grade_level_access)
    return true if grade_level == educator.homeroom.try(:grade)
    false
  end

  # Is the user assigned to that school? (ie, this isn't the same as "do they
  # have access to everything in that school)
  def is_authorized_for_school_id?(educator, school_id)
    return true if educator.districtwide_access?
    return true if educator.school_id == school_id
    false
  end
end
