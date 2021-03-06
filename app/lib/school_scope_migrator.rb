# For manual or semi-automated migrations related to changing school scope
# in definition files or in import jobs.
#
# For example, if removing a school, you might update the definition file,
# then use this class to run a migration that marks all Student and Educator
# records that used to be in scope as inactive.
#
# While school scope in the importers allow them to do "partial imports" for
# migrations, incremental deploys, or debugging, this class allows us to
# ask questions and migrate data that is outside that scope when the scope
# changes.
class SchoolScopeMigrator
  def initialize(options = {})
    @explicit_school_scope = options.fetch(:schools, nil)
    @log = options.fetch(:log, STDOUT)
  end

  def stats
    {
      active_students: count_by_school(Student.active.includes(:school)),
      active_educators: count_by_school(Educator.active.includes(:school))
    }
  end

  def count_by_school(records)
    records.group_by(&:school).map {|k, vs| [k.try(:name), vs.size] }.sort_by {|t| -1 * t[1] }.map {|t| t.join(' -> ') }
  end

  # As defined in definition file, or passed explicitly.
  def schools_within_scope
    return @explicit_school_scope if @explicit_school_scope.present?
    school_local_ids = PerDistrict.new.school_definitions_for_import.map {|j| j['local_id'] }
    School.where(local_id: school_local_ids)
  end

  def migrate_all!
    log "Finding schools..."
    schools = self.schools_within_scope()
    log "There are #{schools.size} School records within scope."
    log
    log
    log "stats, before:"
    log stats()
    log
    log
    migrate_educators!
    log
    log
    migrate_students!
    log
    log
    log "stats, after:"
    log stats()
    log
    log
    log "All done."
  end

  def migrate_educators!
    log "Starting Educators..."
    Educator.transaction do
      log "  Found #{Educator.active.size} active and #{Educator.all.size} total Educator records."
      educator_ids_within_scope = self.educators_within_scope().map(&:id)
      log "  Found #{educator_ids_within_scope.size} Educator records within scope..."
      stale_educators = self.stale_educators()
      log "  Ensuring missing_from_last_export:true for #{stale_educators.size} stale Educator records..."
      log "  Actually setting missing_from_last_export:true for #{stale_educators.active.size} currently active stale Educator records..."
      stale_educators.active.each do |educator|
        educator.update!(missing_from_last_export: true)
      end
      log "  Done updating Educators."
    end
  end

  def migrate_students!
    log "Starting Students..."
    Student.transaction do
      log "  Found #{Student.active.size} active and #{Student.all.size} total Student records."
      student_ids_within_scope = self.students_within_scope().map(&:id)
      log "  Found #{student_ids_within_scope.size} Student records within scope..."
      stale_students = self.stale_students()
      log "  Ensuring missing_from_last_export:true for #{stale_students.size} stale Student records..."
      log "  Actually setting missing_from_last_export:true for #{stale_students.active.size} currently active stale Student records..."
      stale_students.active.each do |student|
        student.update!(missing_from_last_export: true)
      end
      log "  Done updating Students."
    end
  end

  def educators_within_scope
    schools = schools_within_scope()
    active_educators = Educator.active

    (
      active_educators.where(school_id: nil) +
      active_educators.where(school_id: schools.map(&:id)) +
      active_educators.where(login_name: PerDistrict.new.educator_login_names_whitelisted_as_active())
    ).uniq
  end

  def stale_educators
    Educator.all.where.not(id: educators_within_scope().map(&:id))
  end

  def students_within_scope
    schools = schools_within_scope()
    active_students = Student.active
    (
      active_students.where(school_id: nil) +
      active_students.where(school_id: schools.map(&:id))
    ).uniq
  end

  def stale_students
    Student.all.where.not(id: students_within_scope().map(&:id))
  end

  def log(msg = '')
    @log.puts msg
  end
end
