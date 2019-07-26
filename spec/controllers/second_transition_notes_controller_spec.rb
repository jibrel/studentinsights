# typed: false
require 'rails_helper'

RSpec.describe SecondTransitionNotesController, type: :controller do
  let!(:pals) { TestPals.create! }

  def create_note_attrs(attrs = {})
    {
      recorded_at: pals.time_now - 4.days,
      form_key: SecondTransitionNote::SOMERVILLE_TRANSITION_2019,
      starred: false,
      form_json: {
        'strengths' => 'foo strengths',
        'connecting' => 'foo connecting',
        'community' => 'foo community',
        'peers' => 'foo peers',
        'family' => 'foo family',
        'other' => 'foo other',
      },
      restricted_text: 'DANGEROUS restricted text foo'
    }.merge(attrs)
  end

  describe '#transition_students_json' do
    def get_transition_students_json(educator, params = {})
      sign_in(educator)
      request.env['HTTPS'] = 'on'
      get :transition_students_json, params: params.merge(format: :json)
    end

    def expect_single_transition_note_for_student_id(response, student_id)
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json.keys).to eq ['students']
      expect(json['students'].size).to eq 1
      expect(json['students'].first['id']).to eq student_id
      expect(json['students'].first['second_transition_notes'].size).to eq 1
      expect(json['students'].first['second_transition_notes'].first['student_id']).to eq student_id
    end

    def expect_no_students(response)
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json.keys).to eq ['students']
      expect(json['students'].size).to eq 0
    end

    it 'guards access' do
      (Educator.all - [pals.west_counselor, pals.shs_sofia_counselor]).each do |educator|
        get_transition_students_json(educator)
        expect(response.status).to eq 403
      end
    end

    it 'returns no students for Sofia if HOUSEMASTERS_AUTHORIZED_FOR_GRADE_8 not set' do
      get_transition_students_json(pals.shs_sofia_counselor)
      expect_no_students(response)
    end

    it 'includes student for Les, with proper switches' do
      get_transition_students_json(pals.west_counselor)
      expect_single_transition_note_for_student_id(response, pals.west_eighth_ryan.id)
    end

    it 'includes student for Sofia, with proper switches' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('HOUSEMASTERS_AUTHORIZED_FOR_GRADE_8').and_return('true')
      get_transition_students_json(pals.shs_sofia_counselor)
      expect_single_transition_note_for_student_id(response, pals.west_eighth_ryan.id)
    end

    it 'returns expected shape' do
      get_transition_students_json(pals.west_counselor)
      expect_single_transition_note_for_student_id(response, pals.west_eighth_ryan.id)
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json.keys).to eq ['students']
      expect(json['students'].first.keys).to contain_exactly(*[
        'id',
        'has_photo',
        'first_name',
        'last_name',
        'counselor',
        'grade',
        'school',
        'second_transition_notes'
      ])
      expect(json['students'].first['second_transition_notes'].first.keys).to contain_exactly(*[
        'id',
        'educator_id',
        'recorded_at',
        'starred',
        'student_id'
      ])
    end
  end

  describe '#save_json' do
    def post_save_json(educator, student_id, params = {})
      sign_in(educator)
      request.env['HTTPS'] = 'on'
      post :save_json, params: params.merge({
        format: :json,
        educator_id: educator.id,
        student_id: student_id
      })
    end

    it 'guards access' do
      attrs = create_note_attrs()
      (Educator.all - [pals.west_counselor]).each do |educator|
        post_save_json(educator, pals.west_eighth_ryan.id, attrs)
        expect(response.status).to eq 403
      end
    end

    it 'works to create' do
      attrs = create_note_attrs()
      post_save_json(pals.west_counselor, pals.west_eighth_ryan.id, attrs)
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json.keys).to eq ['id']
    end

    it 'works to update' do
      note = SecondTransitionNote.create!(create_note_attrs({
        educator_id: pals.west_counselor.id,
        student_id: pals.west_eighth_ryan.id
      }))
      expect(note.reload.starred).to eq false
      updated_attrs = create_note_attrs(second_transition_note_id: note.id, starred: true)
      post_save_json(pals.west_counselor, pals.west_eighth_ryan.id, updated_attrs)

      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json).to eq('id' => note.id)
      expect(note.reload.starred).to eq true
    end
  end

  describe '#delete_json' do
    def delete_json(educator, params = {})
      sign_in(educator)
      request.env['HTTPS'] = 'on'
      delete :delete_json, params: params.merge(format: :json)
    end

    it 'guards access' do
      note = SecondTransitionNote.create!(create_note_attrs({
        educator_id: pals.west_counselor.id,
        student_id: pals.west_eighth_ryan.id
      }))
      (Educator.all - [pals.west_counselor]).each do |educator|
        delete_json(educator, {
          student_id: pals.west_eighth_ryan.id,
          second_transition_note_id: note.id
        })
        expect(response.status).to eq 403
      end
    end
  end

  describe '#restricted_text_json' do
    def restricted_text_json(educator, params = {})
      sign_in(educator)
      request.env['HTTPS'] = 'on'
      get :restricted_text_json, params: params.merge(format: :json)
    end

    it 'guards access' do
    end
  end

  describe '#next_student_json' do
    def next_student_json(educator, params = {})
      sign_in(educator)
      request.env['HTTPS'] = 'on'
      get :next_student_json, params: params.merge(format: :json)
    end

    it 'guards access' do
      SecondTransitionNote.create!(create_note_attrs({
        educator_id: pals.west_counselor.id,
        student_id: pals.west_eighth_ryan.id
      }))
      (Educator.all - [pals.west_counselor]).each do |educator|
        next_student_json(educator, student_id: pals.west_eighth_ryan.id)
        expect(response.status).to eq 403
      end
    end

    it 'works with no other students' do
      next_student_json(pals.west_counselor, student_id: pals.west_eighth_ryan.id)
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json).to eq({
        'next_student_id' => pals.west_eighth_ryan.id,
        'previous_student_id' => pals.west_eighth_ryan.id
      })
    end

    it 'wraps around' do
      student = FactoryBot.create(:student, grade: '8', school_id: pals.west.id)
      next_student_json(pals.west_counselor, student_id: pals.west_eighth_ryan.id)
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json).to eq({
        'next_student_id' => student.id,
        'previous_student_id' => student.id
      })
    end
  end
end
