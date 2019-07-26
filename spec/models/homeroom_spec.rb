# typed: false
require 'rails_helper'

RSpec.describe Homeroom do

  describe '#school_matches_educator_school' do
    let!(:pals) { TestPals.create! }

    context 'school is different from educator school' do
      let(:healey_kindergarten_homeroom) { pals.healey_kindergarten_homeroom }
      let(:west) { pals.west }

      it 'is invalid' do
        healey_kindergarten_homeroom.school = west
        expect(healey_kindergarten_homeroom).to be_invalid
        expect(healey_kindergarten_homeroom.errors[:school]).to eq ["does not match educator's school"]
      end
    end
  end

  describe '#grade' do
    context 'with PK student' do
      let(:homeroom) { FactoryBot.create(:homeroom_with_pre_k_student) }
      it 'is "PK"' do
        expect(homeroom.grade).to eq "PK"
      end
    end
    context 'with 2nd grade student' do
      let(:homeroom) { FactoryBot.create(:homeroom_with_second_grader) }
      it 'is "2"' do
        expect(homeroom.grade).to eq "2"
      end
    end
  end

end
