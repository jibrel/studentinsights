require 'rails_helper'

describe ReadingController, :type => :controller do
  before { request.env['HTTPS'] = 'on' }
  let!(:pals) { TestPals.create! }
  let!(:time_now) { pals.time_now }

  # write env
  before do
    @READING_ENTRY_OPEN_BENCHMARK_PERIODS_JSON = ENV['READING_ENTRY_OPEN_BENCHMARK_PERIODS_JSON']
    ENV['READING_ENTRY_OPEN_BENCHMARK_PERIODS_JSON'] = '{"periods":[{"benchmark_school_year":2018, "benchmark_period_key":"winter"}]}'
  end

  after do
    ENV['READING_ENTRY_OPEN_BENCHMARK_PERIODS_JSON'] = @READING_ENTRY_OPEN_BENCHMARK_PERIODS_JSON
  end

  # read env
  before do
    @READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON = ENV['READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON']
    ENV['READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON'] = {
      "#{pals.healey.id}:KF" => [pals.uri.login_name],
      "#{pals.west.id}:5" => [pals.uri.login_name]
    }.to_json
  end

  after do
    ENV['READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON'] = @READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON
  end

  describe '#reading_json' do
    it 'guards access based on READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON' do
      (Educator.all - [pals.uri]).each do |educator|
        sign_in(educator)
        get :reading_json, params: {
          school_slug: 'hea',
          grade: 'KF'
        }
        expect(response.status).to eq 302
      end
    end

    it 'works when no data' do
      sign_in(pals.uri)
      get :reading_json, params: {
        school_slug: 'hea',
        grade: 'KF'
      }
      expect(response.status).to eq 200
      json = JSON.parse(response.body)
      expect(json.keys).to eq ['school', 'entry_doc', 'reading_students', 'latest_mtss_notes']
      expect(json['reading_students']).to eq([{
        "id"=>pals.healey_kindergarten_student.id,
        "grade"=>"KF",
        "first_name"=>"Garfield",
        "last_name"=>"Skywalker",
        "plan_504"=>nil,
        "limited_english_proficiency"=>nil,
        "ell_transition_date"=>nil,
        "star_reading_results"=>[],
        "dibels_results"=>[],
        "access"=>{
          "composite"=>nil,
          "comprehension"=>nil,
          "literacy"=>nil,
          "oral"=>nil,
          "listening"=>nil,
          "reading"=>nil,
          "speaking"=>nil,
          "writing"=>nil
        },
        "f_and_p_assessments"=>[],
        "ed_plans"=>[],
        "homeroom"=>{
          "id"=>pals.healey_kindergarten_homeroom.id,
          "name"=>"HEA 003",
          "slug"=>"hea-003",
          "educator"=>{
            "id"=>pals.healey_vivian_teacher.id,
            "email"=>"vivian@demo.studentinsights.org",
            "full_name"=>"Teacher, Vivian"
          }
        }
      }])
      expect(json["entry_doc"]).to eq({})
      expect(json["latest_mtss_notes"]).to eq([])
    end
  end

  describe '#update_data_point_json' do
    def put_update_data_point_json(params = {})
      put :update_data_point_json, params: {
        student_id: pals.healey_kindergarten_student.id,
        school_id: pals.healey.id,
        grade: 'KF',
        benchmark_school_year: 2018,
        benchmark_period_key: 'winter',
        benchmark_assessment_key: 'dibels_dorf_wpm',
        value: 'self-conscious about making errors'
      }.merge(params)
    end

    it 'guards access based on READING_ENTRY_EDUCATOR_AUTHORIZATIONS_JSON' do
      (Educator.all - [pals.uri]).each do |educator|
        sign_in(educator)
        put_update_data_point_json()
        expect(response.status).to eq 302
      end
    end

    it 'guards access based on open periods' do
      (Educator.all - [pals.uri]).each do |educator|
        sign_in(educator)
        put_update_data_point_json(benchmark_school_year: 2017)
        expect(response.status).to eq 302
        put_update_data_point_json(benchmark_period_key: 'summer')
        expect(response.status).to eq 302
      end
    end

    it 'works end-to-end, adding two data points, then reading them' do
      sign_in(pals.uri)
      put_update_data_point_json({
        benchmark_assessment_key: 'instructional_needs',
        value: 'phonological awareness, segmenting'
      })
      expect(response.status).to eq 201
      expect(response.body).to eq ''

      put_update_data_point_json({
        benchmark_assessment_key: 'dibels_dorf_acc',
        value: 'multisyllabic decoding'
      })
      expect(response.status).to eq 201
      expect(response.body).to eq ''

      # verify storage in database
      reading_benchmark_data_points = ReadingBenchmarkDataPoint.where(student_id: pals.healey_kindergarten_student.id)
      expect(reading_benchmark_data_points.as_json(except: [:id, :created_at, :updated_at])).to eq([{
        "student_id"=>pals.healey_kindergarten_student.id,
        "benchmark_school_year"=>2018,
        "benchmark_period_key"=>"winter",
        "benchmark_assessment_key"=>"instructional_needs",
        "json"=>{
          "value"=>"phonological awareness, segmenting"
        },
        "educator_id"=>pals.uri.id,
      }, {
        "student_id"=>pals.healey_kindergarten_student.id,
        "benchmark_school_year"=>2018,
        "benchmark_period_key"=>"winter",
        "benchmark_assessment_key"=>"dibels_dorf_acc",
        "json"=>{
          "value"=>"multisyllabic decoding"
        },
        "educator_id"=>pals.uri.id
      }])

      # verify read path
      get :reading_json, params: {
        school_slug: 'hea',
        grade: 'KF'
      }
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)['entry_doc']).to eq({
        pals.healey_kindergarten_student.id.to_s => {
          "instructional_needs"=>"phonological awareness, segmenting",
          "dibels_dorf_acc"=>"multisyllabic decoding"
        }
      })
    end
  end
end