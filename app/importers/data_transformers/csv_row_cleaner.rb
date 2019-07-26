# typed: ignore
class CsvRowCleaner < Struct.new :row
  DATE_HEADERS = [:event_date, :date_taken]

  def dirty_data?
    !clean_date?
  end

  def transform_row
    row[date_header] = parsed_date unless date_header.nil?
    row
  end

  private
  def clean_date?
    return true if date_header.blank?       # <= No dates here, so no more checks to do
    return false if date_from_row.blank?    # <= Column that should be a date is blank
    return false unless parsed_date         # <= Column can't be parsed
    return false if date_out_of_range       # <= Column is out of range
    return true                             # <= Column is a parsable, reasonable date
  end

  def headers
    @headers ||= row.headers
  end

  def date_header
    @date_header ||= headers.detect { |header| header.in? DATE_HEADERS }
  end

  def date_from_row
    row[date_header]
  end

  def parsed_date
    @parsed_date ||= begin
      return date_from_row if date_from_row.is_a?(DateTime)
      PerDistrict.new.parse_date_during_import(date_from_row)
    rescue ArgumentError
      false
    end
  end

  def date_out_of_range
    (parsed_date < (Date.today - 50.years)) || (Date.today < parsed_date)
  end
end
