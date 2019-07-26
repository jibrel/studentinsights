# typed: false
require 'rails_helper'

RSpec.describe Service do
  let!(:student) { FactoryBot.create(:student) }
  let!(:educator) { FactoryBot.create(:educator) }
  let(:service) { FactoryBot.create(:service) }

  let!(:active_service) { FactoryBot.create(:service, id: 70001, discontinued_at: nil) }
  let!(:another_active_service) { FactoryBot.create(:service, id: 70002, discontinued_at: nil) }

  let!(:discontinued_now) {
    service = FactoryBot.create(:service, id: 70003, recorded_by_educator: educator, discontinued_at: Time.now)
    service
  }

  let!(:past_discontinued) {
    service = FactoryBot.create(:service, id: 70004, recorded_by_educator: educator, discontinued_at: Time.now - 1.day)
    service
  }

  let!(:future_discontinued) {
    service = FactoryBot.create(:service, id: 70005, recorded_by_educator: educator, discontinued_at: Time.now + 1.day)
    service
  }

  let!(:another_future_discontinued) {
    service = FactoryBot.create(:service, id: 70006, recorded_by_educator: educator, discontinued_at: Time.now + 2.days)
    service
  }

  describe '.active' do
    it 'collects the correct services' do
      active_ids = Service.active.map(&:id).sort
      expect(active_ids).to eq [70001, 70002, 70005, 70006]
    end
  end

  describe '.never_discontinued' do
    it 'collects the correct services' do
      never_discontinued_ids = Service.never_discontinued.pluck(:id).sort
      expect(never_discontinued_ids).to eq [70001, 70002]
    end
  end

  describe '.future_discontinue' do
    it 'collects the correct services' do
      future_discontinued_ids = Service.future_discontinue.pluck(:id).sort
      expect(future_discontinued_ids).to eq [70005, 70006]
    end
  end

  describe '.discontinued' do
    it 'collects the correct services' do
      discontinued_ids = Service.discontinued.pluck(:id).sort
      expect(discontinued_ids).to eq [70003, 70004]
    end
  end

  describe '#must_be_discontinued_after_service_start_date' do

    context 'recorded before start date' do
      let(:invalid_service) { FactoryBot.build(:service, discontinued_at: service.date_started - 1.day)}
      it 'is invalid' do
        expect(invalid_service).to be_invalid
      end
    end

    context 'recorded after start date' do
      let(:valid_service) { FactoryBot.build(:service, discontinued_at: service.date_started + 1.day)}
      it 'valid' do
        expect(valid_service).to be_valid
      end
    end

  end

  describe '#discontinued_by_educator' do
    it 'can serialize through association' do
      pals = TestPals.create!
      service = FactoryBot.build(:service, {
        service_type_id: 507,
        student_id: pals.healey_kindergarten_student.id,
        recorded_by_educator_id: pals.healey_vivian_teacher.id,
        date_started: pals.time_now - 8.days,
        discontinued_by_educator_id: pals.uri.id,
        discontinued_at: pals.time_now - 1.day
      })
      expect(service.as_json(include: {
        discontinued_by_educator: {
          only: [:id, :email]
        }
      })['discontinued_by_educator']).to eq({
        'id' => pals.uri.id,
        'email' => "uri@demo.studentinsights.org"
      })
    end
  end
end
