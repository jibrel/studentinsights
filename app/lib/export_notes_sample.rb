# typed: true
# This is intended for use in a one-off analysis task.
#
# See NotesReview for group reflection.
class ExportNotesSample
  # This doesn't do any authorization checks.
  def unsafe_csv_without_authorization_checks(options = {})
    sampled_event_notes, total_count = query(options)

    CSV.generate do |csv|
      csv << [
        'options:',
        options.inspect,
        'sampled_event_notes.size:',
        sampled_event_notes.size,
        'total_count:',
        total_count,
      ]
      csv << []
      csv << [
        'event_note.id',
        'hash(event_note.educator_id)',
        'hash(event_note.student.id)',
        'hash(event_note.student.school_id)',
        'hash(bucket)',
        'event_note.student.id',

        'event_note.is_restricted',
        'event_note.event_note_type.name',
        'event_note.text',
      ]
      sampled_event_notes.each do |event_note|
        csv << [
          event_note.id,
          hash(event_note.educator_id),
          hash(event_note.student.id),
          hash(event_note.student.school_id),
          hash([event_note.student.school_id, event_note.student.grade].join(':')),
          event_note.student.id,

          event_note.is_restricted,
          event_note.event_note_type.name,
          event_note.text.gsub(/\n/, ' ')
        ]
      end
    end
  end

  private
  def hash(value)
    Digest::SHA256.hexdigest(value.to_s)
  end

  def query(options = {})
    start_date = options[:start_date]
    end_date = options[:end_date]
    n = options[:n]
    seed = options[:seed]

    # Query in time range
    event_notes = EventNote.all
      .where('recorded_at > ?', start_date)
      .where('recorded_at < ?', end_date.advance(days: 1))
      .includes(:educator)
    total_count = event_notes.size

    # Sample within that, deterministically
    sampled_event_notes = event_notes.sample(n, random: Random.new(seed))

    [sampled_event_notes, total_count]
  end
end
