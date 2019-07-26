# typed: strong
# An upload that an Insights user performed.  It probably created some `StudentVoiceCompletedSurveys`
class StudentVoiceSurveyUpload < ApplicationRecord
  belongs_to :uploaded_by_educator, class_name: 'Educator'
  has_many :student_voice_completed_surveys, dependent: :destroy
  has_many :students, -> { distinct }, through: :student_voice_completed_surveys

  validates :uploaded_by_educator, presence: true
  validates :file_name, presence: true
  validates :file_size, presence: true
  validates :file_digest, presence: true
end
