# typed: strong
# Store a historical data point about grades for a student in a section.
class HistoricalGrade < ApplicationRecord
  belongs_to :student
  belongs_to :section

  validates :student_id, presence: true
  validates :section_id, presence: true
end
