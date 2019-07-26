# typed: ignore
class StudentRow < Struct.new(:row, :homeroom_id, :school_ids_dictionary, :log)
  # Represents a row in a CSV export from Somerville's Aspen X2 student information system.
  # Some of those rows will enter Student Insights, and the data in the CSV will be written into the database.
  #
  # Contrast with student.rb, which is represents a student once they've entered the DB.
  #
  # The `row` CSV object passed quacks like a hash, and the keys are formed from matching the
  # CSV headers.  This means that column order is ignored and all columns will be present as keys.

  def self.build(row)
    new(row).build
  end

  def build
    student = Student.find_or_initialize_by(local_id: row[:local_id])
    student.assign_attributes(attributes)
    student
  end

  private

  def attributes
    demographic_attributes
      .merge(import_metadata_attributes)
      .merge(name_attributes)
      .merge(school_attributes)
      .merge(per_district_attributes)
      .merge({ grade: grade })
      .merge({ homeroom_id: homeroom_id })
  end

  # If the district does not always send all student records in the export,
  # update any rows we read in to indicate that they were present in this
  # export.
  # See also the way `RecordSyncer#process_unmarked_records` is used in `StudentsImporter`.
  def import_metadata_attributes
    if PerDistrict.new.does_students_export_include_rows_for_inactive_students?
      {}
    else
      { missing_from_last_export: false }
    end
  end

  def name_attributes
    name_split = row[:full_name].split(", ")

    case name_split.size
    when 2
      { first_name: name_split[1], last_name: name_split[0] }
    when 1
      { first_name: nil, last_name: name_split[0] }
    end
  end

  def demographic_attributes
    attrs = {}
    [
      :state_id,
      :enrollment_status,
      :home_language,
      :program_assigned,
      :limited_english_proficiency,
      :sped_placement,
      :disability,
      :sped_level_of_need,
      :plan_504,
      :student_address,
      :race,
      :hispanic_latino,
      :gender,
      :primary_phone,
      :primary_email,
    ].map do |key|
      attrs[key] = map_empty_to_nil(row[key])
    end

    attrs
  end

  def map_empty_to_nil(value)
    if value.nil? # set nil if column not in import
      nil
    elsif value == '' # set nil if column is in import, but there's an empty string value
      nil
    else
      value
    end
  end

  def school_attributes
    { school_id: school_rails_id }
  end

  def school_local_id
    row[:school_local_id]
  end

  def school_rails_id
    school_ids_dictionary[school_local_id] if school_local_id.present?
  end

  def grade
    # "08" => "8"
    # "KF" => "KF"

    return row[:grade] if row[:grade].to_i == 0
    row[:grade].to_i.to_s
  end

  # These are different based on the district configuration and export
  def per_district_attributes
    per_district = PerDistrict.new

    # date parsing
    included_attributes = {
      registration_date: per_district.parse_date_during_import(row[:registration_date]),
      date_of_birth: per_district.parse_date_during_import(row[:date_of_birth]),
      free_reduced_lunch: per_district.map_free_reduced_lunch_value_as_workaround(map_empty_to_nil(row[:free_reduced_lunch]))
    }

    if per_district.import_student_house?
      included_attributes.merge!(house: map_empty_to_nil(row[:house]))
    end

    if per_district.import_student_counselor?
      included_attributes.merge!(counselor: per_district.parse_counselor_during_import(row[:counselor]))
    end

    if per_district.import_student_sped_liaison?
      included_attributes.merge!(sped_liaison: per_district.parse_sped_liaison_during_import(row[:sped_liaison]))
    end

    if per_district.import_student_ell_dates?
      included_attributes.merge!({
        ell_entry_date: per_district.parse_date_during_import(row[:ell_entry_date]),
        ell_transition_date: per_district.parse_date_during_import(row[:ell_transition_date])
      })
    end

    included_attributes
  end
end
