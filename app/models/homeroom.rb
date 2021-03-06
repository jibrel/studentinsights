class Homeroom < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :educator, optional: true
  belongs_to :school

  validates :grade, inclusion: { in: [nil] + GradeLevels::ORDERED_GRADE_LEVELS } # deprecated
  validates :name, presence: true, uniqueness: { scope: [:name, :school] }
  validates :slug, presence: true, uniqueness: true
  validates :school, presence: true

  has_many :students, after_add: :update_grade # deprecated

  validate :validate_school_matches_educator_school

  # Query students on-demand rather than using deprecated `grade`,
  # and filters by `active` unless told not to.
  #
  # Returns sorted and compacted list.
  def grades(options = {})
    should_include_inactive = options.fetch(:include_inactive_students, false)
    relevant_students = should_include_inactive ? self.students : self.students.active
    GradeLevels.sort relevant_students.flat_map(&:grade).compact.uniq
  end

  private
  # deprecated, use `#grades` instead.
  #
  # This doesn't work for mixed-grade homerooms (eg, special education).
  # We should migrate to `Homeroom#grades` or querying students on-demand
  # instead.
  def update_grade(student)
    # Set homeroom grade level to be first student's grade level, since
    # we don't have any crosswalk between homerooms and grades in
    # Somerville's Student Information System

    return if self.grade.present?
    return if student.grade.blank?

    update_attribute(:grade, student.grade)
  end

  def validate_school_matches_educator_school
    if educator.present? && educator.school.present?
      if educator.school != school
        errors.add(:school, 'does not match educator\'s school')
      end
    end
  end
end
