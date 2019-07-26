# typed: false
require 'rails_helper'

RSpec.describe X2AssessmentImporter do
  before { Assessment.seed_for_all_districts }

  def make_x2_assessment_importer(options = {})
    X2AssessmentImporter.new(options: {
      school_scope: nil,
      log: LogHelper::FakeLog.new
    }.merge(options))
  end

  def mock_importer_with_csv(importer, filename)
    csv = test_csv_from_file(filename)
    allow(importer).to receive(:download_csv).and_return(csv)
    importer
  end

  def test_csv_from_file(filename)
    file = File.read(filename)
    transformer = StreamingCsvTransformer.new(LogHelper::FakeLog.new)
    transformer.transform(file)
  end

  describe '#import' do
    context 'respects skip_old_records' do
      let!(:student) { FactoryBot.create(:student, local_id: '100') }
      let(:healey) { School.where(local_id: "HEA").first_or_create! }
      let(:csv) { test_csv_from_file("#{Rails.root}/spec/fixtures/fake_x2_assessments.csv") }

      it 'skips older records' do
        log = LogHelper::FakeLog.new
        importer = X2AssessmentImporter.new(options: {
          school_scope: nil,
          log: log,
          skip_old_records: true,
          time_now: Time.parse('2014-06-12')
        })
        allow(importer).to receive(:download_csv).and_return(csv)
        importer.import

        expect(log.output).to include('skipped_old_rows_count: 3')
        expect(log.output).to include('created_rows_count: 3')
        expect(StudentAssessment.count).to eq(3)
      end
    end

    context 'with good data and no Assessment records in the database' do
      let(:csv) { test_csv_from_file() }

      context 'for Healey school' do

        let!(:student) { FactoryBot.create(:student, local_id: '100') }
        let(:healey) { School.where(local_id: "HEA").first_or_create! }
        let(:log) { LogHelper::FakeLog.new }
        let(:importer) { make_x2_assessment_importer(log: log) }
        before { mock_importer_with_csv(importer, "#{Rails.root}/spec/fixtures/fake_x2_assessments.csv") }
        before { importer.import }

        it 'imports only white-listed assessments and logs all assessment types' do
          expect(StudentAssessment.count).to eq 5
          expect(DibelsResult.count).to eq 1
          expect(log.output).to include 'skipped_because_of_test_type: 2'
          expect(log.output).to include '@encountered_test_names_count_map'
          expect(log.output).to include '"MCAS"=>2'
          expect(log.output).to include '"MAP: Reading 2-5 Common Core 2010 V2"=>1'
          expect(log.output).to include '"GRADE"=>1'
          expect(log.output).to include '"WIDA-ACCESS"=>2'
          expect(log.output).to include '"ACCESS"=>1'
        end

        context 'MCAS' do
          let(:assessments) { Assessment.where(family: "MCAS") }

          it 'creates MCAS Mathematics and ELA assessments' do
            expect(assessments.count).to eq 2
            expect(assessments.map(&:subject)).to contain_exactly 'ELA' , 'Mathematics'
          end
          context 'Math' do
            it 'sets the scaled scores and performance levels, growth percentiles correctly' do
              mcas_assessment = Assessment.find_by_family_and_subject('MCAS', 'Mathematics')
              mcas_student_assessment = mcas_assessment.student_assessments.last
              expect(mcas_student_assessment.scale_score).to eq(214)
              expect(mcas_student_assessment.performance_level).to eq('W')
              expect(mcas_student_assessment.growth_percentile).to eq(nil)
            end
          end
          context 'ELA' do
            it 'sets the scaled scores, performance levels, growth percentiles correctly' do
              mcas_assessment = assessments.where(subject: "ELA").first
              mcas_student_assessment = mcas_assessment.student_assessments.last
              expect(mcas_student_assessment.scale_score).to eq(222)
              expect(mcas_student_assessment.performance_level).to eq('NI')
              expect(mcas_student_assessment.growth_percentile).to eq(70)
            end
          end
        end

        context 'DIBELS' do
          it 'creates the correct DIBELS record' do
            expect(DibelsResult.count).to eq 1
            expect(DibelsResult.last.benchmark).to eq 'STRATEGIC'
          end
        end

        context 'ACCESS' do
          let(:assessments) { Assessment.where(family: "ACCESS", subject: "Composite") }
          let(:assessment) { assessments.first }

          it 'creates assessment' do
            expect(assessments.count).to eq 1
          end
          it 'creates three student assessments' do
            results = assessment.student_assessments
            expect(results.count).to eq 3
          end
          it 'sets the scaled scores, performance levels, growth percentiles correctly' do
            last_access_result = assessment.student_assessments.last
            expect(last_access_result.scale_score).to eq(367)
            expect(last_access_result.performance_level).to eq('4.9')
            expect(last_access_result.growth_percentile).to eq(92)
          end
        end
      end
    end
  end

  describe 'integration tests for Bedford MCAS' do
    let!(:pals) { TestPals.create! }
    let!(:csv) { test_csv_from_file("#{Rails.root}/spec/fixtures/assessment_bedford_format_fixture.csv") }

    before do
      allow(PerDistrict).to receive(:new).and_return(PerDistrict.new(district_key: PerDistrict::BEDFORD))
      Assessment.seed_for_all_districts
    end

    it 'works' do
      log = LogHelper::FakeLog.new
      importer = X2AssessmentImporter.new(options: {
        school_scope: nil,
        log: log,
        skip_old_records: true,
        time_now: Time.parse('2018-06-12')
      })
      allow(importer).to receive(:download_csv).and_return(csv)
      importer.import

      expect(log.output).to include('skipped_because_of_test_type: 3')
      expect(log.output).to include('created_rows_count: 8')
      expect(StudentAssessment.count).to eq(8)

      # Mari as an example of properly parsed Old MCAS
      expect(pals.shs_freshman_mari.student_assessments.as_json(except: [:id, :created_at, :updated_at]).first).to include({
        "student_id"=>pals.shs_freshman_mari.id,
        "assessment_id"=> Assessment.find_by(family: 'MCAS', subject: 'ELA').id,
        "date_taken"=> Time.parse('2018-05-15 00:00:00 +0000'),
        "scale_score"=>255,
        "performance_level"=>"P",
        "growth_percentile"=>56,
        "percentile_rank"=>nil,
        "instructional_reading_level"=>nil,
        "grade_equivalent"=>nil
      })

      # Ryan is example of properly parsed Next Generation MCAS
      expect(pals.west_eighth_ryan.student_assessments.as_json(except: [:id, :created_at, :updated_at]).first).to include({
        "student_id"=>pals.west_eighth_ryan.id,
        "assessment_id"=> Assessment.find_by(family: 'Next Gen MCAS', subject: 'Mathematics').id,
        "date_taken"=> Time.parse('2018-05-15 00:00:00 +0000'),
        "scale_score"=>507,
        "performance_level"=>"M",
        "growth_percentile"=>34,
        "percentile_rank"=>nil,
        "instructional_reading_level"=>nil,
        "grade_equivalent"=>nil
      })
    end
  end

  describe 'integration tests for New Bedford MCAS and ACCESS' do
    let!(:pals) { TestPals.create! }
    let!(:csv) { test_csv_from_file("#{Rails.root}/spec/fixtures/assessment_new_bedford_format_fixture.csv") }

    before do
      allow(PerDistrict).to receive(:new).and_return(PerDistrict.new(district_key: PerDistrict::NEW_BEDFORD))
      Assessment.seed_for_all_districts
    end

    it 'works' do
      log = LogHelper::FakeLog.new
      importer = X2AssessmentImporter.new(options: {
        school_scope: nil,
        log: log,
        skip_old_records: true,
        time_now: Time.parse('2018-06-12')
      })
      allow(importer).to receive(:download_csv).and_return(csv)
      importer.import

      expect(log.output).to include('encountered_test_names_count_map: {"MCAS"=>11, "ACCESS"=>8}')
      expect(log.output).to include('skipped_because_of_test_type: 0')
      expect(log.output).to include('created_rows_count: 16')
      expect(log.output).to include('invalid_rows_count: 3') # science
      expect(StudentAssessment.count).to eq(16)

      # Mari as an example of properly parsed Old MCAS
      expect(pals.shs_freshman_mari.student_assessments.as_json(except: [:id, :created_at, :updated_at]).first).to include({
        "student_id"=>pals.shs_freshman_mari.id,
        "assessment_id"=> Assessment.find_by(family: 'MCAS', subject: 'ELA').id,
        "date_taken"=> Time.parse('2018-05-15 00:00:00 +0000'),
        "scale_score"=>255,
        "performance_level"=>"P",
        "growth_percentile"=>56,
        "percentile_rank"=>nil,
        "instructional_reading_level"=>nil,
        "grade_equivalent"=>nil
      })

      # Ryan is example of properly parsed Next Generation MCAS
      expect(pals.west_eighth_ryan.student_assessments.as_json(except: [:id, :created_at, :updated_at]).first).to include({
        "student_id"=>pals.west_eighth_ryan.id,
        "assessment_id"=> Assessment.find_by(family: 'Next Gen MCAS', subject: 'Mathematics').id,
        "date_taken"=> Time.parse('2018-06-30 00:00:00 +0000'),
        "scale_score"=>507,
        "performance_level"=>"M",
        "growth_percentile"=>34,
        "percentile_rank"=>nil,
        "instructional_reading_level"=>nil,
        "grade_equivalent"=>nil
      })

      # Ryan as example of properly parsed ACCESS
      expect(pals.west_eighth_ryan.latest_access_results).to eq({
        :composite=>"3.5",
        :comprehension=>"3.8",
        :literacy=>"3.8",
        :oral=>"2.8",
        :listening=>"3.1",
        :reading=>"1.7",
        :speaking=>"2.4",
        :writing=>"4.2"
      })
    end
  end
end
