# typed: true
# Define when school years start and end.  See also schoolYear.js.
class SchoolYear
  # date: A JS date object or Moment object.
  # returns: Integer representing what the calendar year was in the fall of date's school year.
  def self.first_day_of_school_for_year(year)
    DateTime.new(year, 8, 15)
  end

  # year: An integer year.
  # returns: A moment object representing roughly the last day of that school year (which will
  # be in the following calendar year).
  def self.last_day_of_school_for_year(year)
    DateTime.new(year + 1, 6, 30)
  end

  # Returns DateTime representing the first day of school for the given date_time
  def self.first_day_of_school_for_time(date_time)
    year = to_school_year(date_time)
    first_day_of_school_for_year(year)
  end

  # returns: Integer representing what the calendar year was in the fall of date's school year
  def self.to_school_year(date_time)
    year = date_time.year
    start_of_school_year = self.first_day_of_school_for_year(year)
    is_event_during_fall = (date_time - start_of_school_year) > 0
    if is_event_during_fall
      year
    else
      year - 1
    end
  end

  # Figure out what values of `term_local_id` are within the current quarter
  def self.current_term_local_ids(time_now)
    current_quarter = PerDistrict.new.current_quarter(time_now)
    return ['Q1', 'S1', '1', '9', 'FY'] if current_quarter == 'Q1'
    return ['Q2', 'S1', '1', '9', 'FY'] if current_quarter == 'Q2'
    return ['Q3', 'S2', '2', '9', 'FY'] if current_quarter == 'Q3'
    return ['Q4', 'S2', '2', '9', 'FY'] if current_quarter == 'Q4'
    []
  end
end
