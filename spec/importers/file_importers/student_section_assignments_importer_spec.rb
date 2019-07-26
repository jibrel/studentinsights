# typed: false
require 'rails_helper'

RSpec.describe StudentSectionAssignmentsImporter do
  def make_importer_with_initialization(options = {})
    importer = StudentSectionAssignmentsImporter.new(options: {
      school_scope: nil,
      log: LogHelper::Redirect.instance.file
    }.merge(options))
    importer.instance_variable_set(:@school_ids_dictionary, importer.send(:build_school_ids_dictionary))
    importer
  end

  before { TestPals.seed_somerville_schools_for_test! }
  let(:high_school) { School.find_by_local_id('SHS') }
  let(:student_section_assignments_importer) { make_importer_with_initialization }

  describe 'integration tests' do
    def make_importer(options = {})
      StudentSectionAssignmentsImporter.new(options: {
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

    let!(:east) { School.find_by_local_id('ESCS') }
    let!(:log) { LogHelper::FakeLog.new }
    let!(:importer) { make_importer(log: log) }
    before { mock_importer_with_csv(importer, "#{Rails.root}/spec/fixtures/student_section_assignment_export.txt") }

    # These match the fixture file
    before do
      FactoryBot.create(:student, local_id: '111')
      FactoryBot.create(:student, local_id: '222')
      FactoryBot.create(:student, local_id: '333')
    end

    let!(:east_history) { FactoryBot.create(:course, course_number: 'SOC6', school: east) }
    let!(:shs_history) { FactoryBot.create(:course, course_number: 'SOC6', school: high_school) }
    let!(:shs_ela) { FactoryBot.create(:course, course_number: 'ELA6', school: high_school) }
    let!(:shs_math) { FactoryBot.create(:course, course_number: 'ALG2', school: high_school) }
    let!(:east_history_section) { FactoryBot.create(:section, course: east_history, section_number: 'SOC6-001') }
    let!(:shs_history_section) { FactoryBot.create(:section, course: shs_history, section_number: 'SOC6-001') }
    let!(:shs_ela_section) { FactoryBot.create(:section, course: shs_ela, section_number: 'ELA6-002') }
    let!(:shs_math_section) { FactoryBot.create(:section, course: shs_math, section_number: 'ALG2-004') }

    it 'works' do
      importer.import
      expect(StudentSectionAssignment.count).to eq 4
      expect(log.output).to include '@invalid_student_count: 2'
      expect(log.output).to include '@invalid_course_count: 1'
      expect(log.output).to include '@invalid_section_count: 1'
      expect(log.output).to include ':passed_nil_record_count=>4'
      expect(log.output).to include ':created_rows_count=>4'
    end

    it 'syncs when existing records' do
      # will be unchanged
      StudentSectionAssignment.create!({
        student: Student.find_by_local_id('111'),
        section: east_history_section
      })
      # will be deleted
      StudentSectionAssignment.create!({
        student: Student.find_by_local_id('333'),
        section: shs_math_section
      })
      expect(StudentSectionAssignment.count).to eq 2

      importer.import
      expect(log.output).to include '@invalid_student_count: 2'
      expect(log.output).to include '@invalid_course_count: 1'
      expect(log.output).to include '@invalid_section_count: 1'
      expect(log.output).to include ':passed_nil_record_count=>4'
      expect(log.output).to include ':unchanged_rows_count=>1'
      expect(log.output).to include ':created_rows_count=>3'
      expect(log.output).to include ':destroyed_records_count=>1'
      expect(StudentSectionAssignment.count).to eq 4
    end

  end

  describe '#import_row' do
    let!(:course) { FactoryBot.create(:course, school: high_school) }
    let!(:section) { FactoryBot.create(:section, course: course) }
    let!(:student) { FactoryBot.create(:student) }

    context 'happy path' do
      let(:row) {
        {
          local_id: student.local_id,
          course_number: section.course.course_number,
          school_local_id: 'SHS',
          section_number: section.section_number,
          term_local_id: 'FY'
        }
      }

        before do
          student_section_assignments_importer.send(:import_row, row)
        end

        it 'creates a student section assignment' do
          expect(StudentSectionAssignment.count).to eq(1)
        end

        it 'assigns the proper student to the proper section' do
          expect(StudentSectionAssignment.first.student).to eq(student)
          expect(StudentSectionAssignment.first.section).to eq(section)
        end
    end

    context 'student lasid is missing' do
      let(:row) {
        {
          course_number: section.course.course_number,
          school_local_id: 'SHS',
          section_number: section.section_number,
          term_local_id: 'FY'
        }
      }

      before do
        student_section_assignments_importer.send(:import_row, row)
      end

      it 'does not create a student section assignment' do
        expect(StudentSectionAssignment.count).to eq(0)
      end
    end

    context 'section is missing' do
      let(:row) {
        {
          local_id: student.local_id,
          course_number: section.course.course_number,
          school_local_id: 'SHS',
          term_local_id: 'FY'
        }
      }

      before do
        student_section_assignments_importer.send(:import_row, row)
      end

      it 'does not create a student section assignment' do
        expect(StudentSectionAssignment.count).to eq(0)
      end
    end

    context 'student does not exist' do
      let(:row) {
        {
          local_id: 'NO EXIST',
          course_number: section.course.course_number,
          school_local_id: 'SHS',
          section_number: section.section_number,
          term_local_id: 'FY'
        }
      }

      before do
        student_section_assignments_importer.send(:import_row, row)
      end

      it 'does not create a student section assignment' do
        expect(StudentSectionAssignment.count).to eq(0)
      end
    end

    context 'section does not exist' do
      let(:row) {
        {
          local_id: student.local_id,
          course_number: section.course.course_number,
          school_local_id: 'SHS',
          section_number: 'NO EXIST',
          term_local_id: 'FY'
        }
      }

      before do
        student_section_assignments_importer.send(:import_row, row)
      end

      it 'does not create a student section assignment' do
        expect(StudentSectionAssignment.count).to eq(0)
      end
    end
  end

  describe 'deleting rows' do
    def sync_records(importer)
      syncer = importer.instance_variable_get(:@syncer)
      syncer.delete_unmarked_records!(importer.send(:records_within_scope))
      nil
    end

    let(:log) { LogHelper::Redirect.instance.file }
    let!(:section) { FactoryBot.create(:section) }
    let!(:student) { FactoryBot.create(:student) }
    let(:row) {
      {
        local_id: student.local_id,
        course_number: section.course.course_number,
        school_local_id: section.course.school.local_id,
        section_number: section.section_number,
        term_local_id: section.term_local_id
      }
    }

    context 'happy path' do
      let(:student_section_assignments_importer) do
        make_importer_with_initialization(school_scope: School.pluck(:local_id))
      end

      before do
        FactoryBot.create_list(:student_section_assignment, 20)
        FactoryBot.create(:student_section_assignment, student_id: student.id, section_id: section.id)

        student_section_assignments_importer.send(:import_row, row)
        sync_records(student_section_assignments_importer)
      end

      it 'deletes all student section assignments except the recently imported one' do
        expect(StudentSectionAssignment.count).to eq(1)
      end
    end

    context 'delete only stale assignments from schools being imported' do
      let(:student_section_assignments_importer) do
        make_importer_with_initialization(school_scope: ['SHS'])
      end

      before do
        FactoryBot.create_list(:student_section_assignment, 20)
        FactoryBot.create(:student_section_assignment, student_id: student.id, section_id: section.id)

        student_section_assignments_importer.send(:import_row, row)
        sync_records(student_section_assignments_importer)
      end

      it 'deletes all student section assignments for that school except the recently imported one' do
        expect(StudentSectionAssignment.count).to eq(21)
      end
    end
  end

  describe '#matching_insights_record_for_row' do
    let(:importer) { make_importer_with_initialization }
    let(:student_section_assignment) { importer.send(:matching_insights_record_for_row, row) }
    let(:healey_school) { School.find_by_local_id('HEA') }
    let(:brown_school) { School.find_by_local_id('BRN') }

    context 'happy path' do
      let!(:student) { FactoryBot.create(:high_school_student) }
      let!(:course) {
        FactoryBot.create(
          :course, course_number: 'F100', school: healey_school
        )
      }
      let!(:section) {
        FactoryBot.create(
          :section, course: course, section_number: 'MUSIC-005', term_local_id: 'FY'
        )
      }

      let(:row) {
        {
          local_id: student.local_id,
          section_number: 'MUSIC-005',
          course_number: 'F100',
          school_local_id: 'HEA',
          term_local_id: 'FY'
        }
      }

      it 'assigns the correct values' do
        expect(student_section_assignment.student).to eq(student)
        expect(student_section_assignment.section).to eq(section)
      end
    end

    context 'section with same section_number at different school' do
      let!(:another_course) {
        FactoryBot.create(:course, course_number: 'F100', school: brown_school)
      }
      let!(:another_section) {
        FactoryBot.create(
          :section, course: another_course, section_number: 'MUSIC-005', term_local_id: 'FY'
        )
      }

      let!(:student) { FactoryBot.create(:high_school_student) }
      let!(:course) {
        FactoryBot.create(:course, course_number: 'F100', school: healey_school)
      }
      let!(:section) {
        FactoryBot.create(
          :section, course: course, section_number: 'MUSIC-005', term_local_id: 'FY'
        )
      }

      let(:row) {
        {
          local_id: student.local_id,
          section_number: 'MUSIC-005',
          course_number: 'F100',
          school_local_id: 'HEA',
          term_local_id: 'FY'
        }
      }

      it 'assigns the correct values' do
        expect(student_section_assignment.student).to eq(student)
        expect(student_section_assignment.section).to eq(section)
      end
    end

    context 'no course info or school_local_id' do
      let!(:section) { FactoryBot.create(:section) }
      let!(:student) { FactoryBot.create(:high_school_student) }
      let(:row) {
        {
          local_id: student.local_id,
          section_number: section.section_number,
        }
      }

      it 'returns nil' do
        expect(student_section_assignment).to be_nil
      end
    end
  end
end
