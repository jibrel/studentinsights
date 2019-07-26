# typed: false
# For groups of educators to reflect as a team.
# Aimed at not identifying individual teachers, avoiding accountability,
# thinking about groups and support systems or reflecting as a group.
#
# See ExportNotesSample for coding.
class NotesReview
  def initialize(options = {})
    @log = options.fetch(:log, STDOUT)
  end

  def high_school_teachers
    ensure_somerville_only!
    school_id = School.find_by_local_id('SHS')
    compute_and_printout({
      educator_id: Educator.where(school_id: school_id, schoolwide_access: false).map(&:id),
      student_id: Student.active.where(school_id: school_id).map(&:id)
    })
  end

  def high_school_counselors
    ensure_somerville_only!
    compute_and_printout({
      educator_id: EducatorLabel.where(label_key: 'use_counselor_based_feed').map(&:educator_id)
    })
  end

  def high_school_housemasters
    ensure_somerville_only!
    compute_and_printout({
      educator_id: EducatorLabel.where(label_key: 'use_housemaster_based_feed').map(&:educator_id)
    })
  end

  private
  def ensure_somerville_only!
    raise 'somerville only!' unless PerDistrict.new.district_key == PerDistrict::SOMERVILLE
  end

  def section(title)
    "\n\n#{title}\n--------------------------"
  end

  def compute_and_printout(where_event_notes, options = {})
    time_now = options.fetch(:time_now, Time.now)
    n_days_back = options.fetch(:n_days_back, 45)
    time_interval = n_days_back.days
    event_notes = EventNote.where(where_event_notes).where('created_at > ?', time_now - time_interval)
    levels = SomervilleHighLevels.new(time_interval: time_interval)

    lines = []
    lines << "In the last #{n_days_back} days since #{time_now}..."

    lines << section("How many notes?")
    lines << event_notes.size

    lines << section("About whom (grade levels)?")
    lines << event_notes.includes(:student).group_by {|n| n.student.grade }.sort_by {|key, values| key.to_i }.map {|key, values| [key, values.size].join("\t")}

    lines << section("About whom (houses)?")
    lines << event_notes.includes(:student).group_by {|n| n.student.house }.sort_by {|key, values| key.to_i }.map {|key, values| [key, values.size].join("\t")}

    lines << section("About whom (levels)?")
    lines << levels.unsafe_students_with_levels_json(event_notes.includes(:student).map(&:student).uniq, time_now).group_by {|json| json['level']['level_number'] }.sort_by {|key, values| key.to_i }.map {|key, values| [key, values.size].join("\t")}

    lines << section("By whom (educator names hidden)?")
    lines << event_notes.includes(:educator).group_by {|n| Digest::SHA256.hexdigest(n.educator.login_name) }.sort_by {|key, values| -1 * values.size }.map {|key, values| [key, values.size].join("\t")}

    lines << section("What does the quality look like?")
    lines << event_notes.map(&:text).join("\n\n---------------\n\n")

    @log.puts lines.join("\n")
    nil
  end
end
