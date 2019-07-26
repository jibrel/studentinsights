# typed: strict
class DisciplineIncident < ApplicationRecord
  belongs_to :student
  validates_presence_of :student, :occurred_at
end
