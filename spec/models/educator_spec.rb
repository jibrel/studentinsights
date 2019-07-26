# typed: false
require 'rails_helper'

RSpec.describe Educator do

  describe 'has Devise hooks' do
    it 'allow writing password but not reading, only for Devise' do
      educator = FactoryBot.build(:educator)
      educator.password = 'foo'
      expect(educator.respond_to?(:password)).to eq false
      expect(educator.attributes.has_key?(:password)). to eq false
    end

    it 'allow writing login_text but not reading, only for Devise' do
      educator = FactoryBot.build(:educator)
      educator.login_text = 'foo'
      expect(educator.respond_to?(:login_text)).to eq false
      expect(educator.attributes.has_key?(:login_text)). to eq false
    end
  end

  describe '#as_json' do
    it 'does not include student_searchbar_json' do
      educator = FactoryBot.build(:educator)
      expect(educator.as_json.has_key?('student_searchbar_json')).to be false
    end
  end

  it 'allows creating Educator without a school, so we can whitelist import admin users outside pilot schools' do
    expect(FactoryBot.build(:educator, school: nil)).to be_valid
  end

  describe '#admin_gets_access_to_all_students' do
    context 'admin with access to all students' do
      let(:admin) { FactoryBot.build(:educator, :admin) }
      it 'is valid' do
        expect(admin).to be_valid
      end
    end
    context 'admin without access to all students' do
      let(:admin) { FactoryBot.build(:educator, :admin, restricted_to_sped_students: true) }
      it 'is invalid' do
        expect(admin).to be_invalid
      end
    end
  end

  describe 'grade level access' do
    context 'mix of strings and not strings' do
      let(:educator) { FactoryBot.create(:educator, grade_level_access: ['3', 4]) }
      it 'is coerced into an array of strings' do
        expect(educator.grade_level_access).to eq ["3", "4"]
      end
    end
    context 'only integers' do
      let(:educator) { FactoryBot.create(:educator, grade_level_access: [3, 4]) }
      it 'is coerced into an array of strings' do
        expect(educator.grade_level_access).to eq ["3", "4"]
      end
    end
  end

  describe '#is_authorized_for_student' do
    let(:authorized?) { educator.is_authorized_for_student(student) }
    let(:healey) { FactoryBot.create(:healey) }
    let(:brown) { FactoryBot.create(:brown) }

    context 'educator has districtwide access' do
      let(:student) { FactoryBot.create(:student, school: healey) }
      let(:educator) {
        FactoryBot.create(:educator, school: brown, districtwide_access: true)
      }

      it 'grants access despite student being from different school' do
        expect(authorized?).to be true
      end
    end

    context 'student belongs to same school' do
      let(:student) { FactoryBot.create(:student, school: healey) }

      context 'educator does not have schoolwide access' do
        let(:educator) { FactoryBot.create(:educator, school: healey) }
        it 'is not authorized' do
          expect(authorized?).to be false
        end
      end

      context 'educator has schoolwide access' do
        let(:educator) { FactoryBot.create(:educator, school: healey, schoolwide_access: true) }
        it 'is authorized' do
          expect(authorized?).to be true
        end
      end

      context 'educator has student in a section' do
        let!(:educator) { FactoryBot.create(:educator, school: healey) }
        let!(:course) { FactoryBot.create(:course) }
        let!(:section) { FactoryBot.create(:section, course: course) }
        let!(:esa) { FactoryBot.create(:educator_section_assignment, educator: educator, section: section) }
        let!(:ssa) { FactoryBot.create(:student_section_assignment, student: student, section: section) }

        it 'is authorized' do
          expect(authorized?).to be true
        end
      end

    end

    context 'student belongs to different school' do
      let(:educator) { FactoryBot.create(:educator, school: healey, schoolwide_access: true) }
      let(:student) { FactoryBot.create(:student, school: brown) }

      it 'is not authorized' do
        expect(authorized?).to be false
      end
    end

  end

  describe '#local_email' do
    context 'no email' do
      it 'is invalid' do
        expect(FactoryBot.build(:educator, :without_email)).to be_invalid
      end
    end
  end

  describe '#allowed_homerooms' do
    let!(:school) { FactoryBot.create(:healey) }
    let!(:other_school) { FactoryBot.create(:brown) }

    context 'schoolwide_access' do
      let(:educator) { FactoryBot.create(:educator, schoolwide_access: true, school: school) }
      let!(:homeroom_101) { FactoryBot.create(:homeroom, school: school) }
      let!(:homeroom_102) { FactoryBot.create(:homeroom, school: school) }
      let!(:homeroom_103) { FactoryBot.create(:homeroom, grade: '2', school: school) }

      it 'returns all homerooms in the school' do
        expect(educator.allowed_homerooms.sort).to eq [
          homeroom_101, homeroom_102, homeroom_103
        ].sort
      end
    end

    context 'districtwide_access' do
      let(:educator) { FactoryBot.create(:educator, districtwide_access: true, school: school) }
      let!(:homeroom_101) { FactoryBot.create(:homeroom, school: school) }
      let!(:homeroom_102) { FactoryBot.create(:homeroom, school: other_school) }
      let!(:homeroom_103) { FactoryBot.create(:homeroom, grade: '2', school: other_school) }

      it 'returns all homerooms in the school' do
        expect(educator.allowed_homerooms.sort).to eq [
          homeroom_101, homeroom_102, homeroom_103
        ].sort
      end
    end

    context 'homeroom teacher' do
      let(:educator) { FactoryBot.create(:educator, school: school) }
      let!(:homeroom_101) { FactoryBot.create(:homeroom, grade: 'K', educator: educator, school: school) }
      let!(:homeroom_102) { FactoryBot.create(:homeroom, grade: 'K', school: school) }
      let!(:homeroom_103) { FactoryBot.create(:homeroom, grade: '2', school: school) }
      let!(:homeroom_brn) { FactoryBot.create(:homeroom, grade: '2', school: other_school) }

      it 'returns educator\'s homeroom plus other homerooms at same grade level in same school' do
        expect(educator.allowed_homerooms.sort).to eq [homeroom_101, homeroom_102].sort
      end
    end

    context 'teacher with grade level access' do
      let(:educator) { FactoryBot.create(:educator, grade_level_access: ['2'], school: school) }
      let!(:homeroom_101) { FactoryBot.create(:homeroom, grade: 'K', school: school) }
      let!(:homeroom_102) { FactoryBot.create(:homeroom, grade: 'K', school: school) }
      let!(:homeroom_103) { FactoryBot.create(:homeroom, grade: '2', school: school) }

      it 'returns all homerooms that match the grade level access' do
        expect(educator.allowed_homerooms).to eq [homeroom_103]
      end
    end

  end

  describe '#allowed_sections' do
    let!(:school) { FactoryBot.create(:healey) }
    let!(:other_school) { FactoryBot.create(:brown) }
    let!(:in_school_course) { FactoryBot.create(:course, school: school) }
    let!(:in_school_section) { FactoryBot.create(:section, course: in_school_course) }
    let!(:out_of_school_course) { FactoryBot.create(:course, school: other_school)}
    let!(:out_of_school_section) { FactoryBot.create(:section, course: out_of_school_course) }

    context 'schoolwide_access' do
      let(:schoolwide_educator) { FactoryBot.create(:educator, school: school, schoolwide_access: true)}
      it 'returns all sections in the school' do
        expect(schoolwide_educator.allowed_sections.sort).to eq [
          in_school_section
        ].sort
      end
    end

    context 'districtwide_access' do
      let(:districtwide_educator) { FactoryBot.create(:educator, school: school, districtwide_access: true)}
      it 'returns all sections in the district' do
        expect(districtwide_educator.allowed_sections.sort).to eq [
          in_school_section, out_of_school_section
        ].sort
      end
    end

    context 'regular teacher' do
      let(:educator) { FactoryBot.create(:educator, school: school) }
      let!(:other_in_school_section) { FactoryBot.create(:section, course: in_school_course) }
      let!(:esa) { FactoryBot.create(:educator_section_assignment, educator: educator, section: in_school_section) }
      let!(:other_esa) { FactoryBot.create(:educator_section_assignment, educator: educator, section: other_in_school_section) }
      it 'returns all sections assigned to the educator' do
        expect(educator.allowed_sections.sort).to eq [
          in_school_section, other_in_school_section
        ].sort
      end
    end
  end

  describe '#is_authorized_for_section' do
    let!(:school) { FactoryBot.create(:healey) }
    let!(:other_school) { FactoryBot.create(:brown) }
    let!(:in_school_course) { FactoryBot.create(:course, school: school) }
    let!(:in_school_section) { FactoryBot.create(:section, course: in_school_course) }
    let!(:out_of_school_course) { FactoryBot.create(:course, school: other_school)}
    let!(:out_of_school_section) { FactoryBot.create(:section, course: out_of_school_course) }

    context 'schoolwide_access' do
      let(:schoolwide_educator) { FactoryBot.create(:educator, school: school, schoolwide_access: true)}

      it 'has access to a section in their school' do
        expect(schoolwide_educator.is_authorized_for_section(in_school_section)).to be true
      end

      it 'does not have access to a section outside their school' do
        expect(schoolwide_educator.is_authorized_for_section(out_of_school_section)).to be false
      end
    end

    context 'districtwide_access' do
      let(:districtwide_educator) { FactoryBot.create(:educator, school: school, districtwide_access: true)}

      it 'has access to a section outside their school' do
        expect(districtwide_educator.is_authorized_for_section(out_of_school_section)).to be true
      end
    end

    context 'regular teacher' do
      let(:educator) { FactoryBot.create(:educator, school: school) }
      let!(:other_in_school_section) { FactoryBot.create(:section, course: in_school_course) }
      let!(:esa) { FactoryBot.create(:educator_section_assignment, educator: educator, section: in_school_section) }

      it 'has access to a section assigned to that educator' do
        expect(educator.is_authorized_for_section(in_school_section)).to be true
      end

      it 'does not have access to a section not assigned to that educator' do
        expect(educator.is_authorized_for_section(other_in_school_section)).to be false
      end

    end
  end

  describe '#labels' do
    let!(:pals) { TestPals.create! }
    it 'works' do
      expect(pals.shs_bill_nye.labels).to eq ['shs_experience_team', 'should_show_low_grades_box', 'should_show_levels_shs_link']
      expect(pals.shs_jodi.labels).to eq ['shs_experience_team', 'can_upload_student_voice_surveys', 'should_show_levels_shs_link']
      expect(pals.uri.labels).to contain_exactly(*[
        'can_upload_student_voice_surveys',
        'should_show_levels_shs_link',
        'enable_reading_benchmark_data_entry',
        'enable_equity_experiments',
        'enable_reading_debug',
        'profile_enable_minimal_reading_data'
      ])
    end
  end
end
