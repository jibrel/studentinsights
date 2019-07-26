# typed: true
class AddKeys < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key "courses", "schools", name: "courses_school_id_fk"
    add_foreign_key "educators", "schools", name: "educators_school_id_fk"
    add_foreign_key "event_note_attachments", "event_notes", name: "event_note_attachments_event_note_id_fk"
    add_foreign_key "event_note_revisions", "event_notes", name: "event_note_revisions_event_note_id_fk"
    add_foreign_key "event_notes", "educators", name: "event_notes_educator_id_fk"
    add_foreign_key "event_notes", "event_note_types", name: "event_notes_event_note_type_id_fk"
    add_foreign_key "event_notes", "students", name: "event_notes_student_id_fk"
    add_foreign_key "homerooms", "educators", name: "homerooms_educator_id_fk"
    add_foreign_key "homerooms", "schools", name: "homerooms_school_id_fk"
    add_foreign_key "iep_documents", "students", name: "iep_documents_student_id_fk"
    add_foreign_key "interventions", "educators", name: "interventions_educator_id_fk"
    add_foreign_key "interventions", "intervention_types", name: "interventions_intervention_type_id_fk"
    add_foreign_key "interventions", "students", name: "interventions_student_id_fk"
    add_foreign_key "sections", "courses", name: "sections_course_id_fk"
    add_foreign_key "service_uploads", "educators", column: "uploaded_by_educator_id", name: "service_uploads_uploaded_by_educator_id_fk"
    add_foreign_key "services", "educators", column: "recorded_by_educator_id", name: "services_recorded_by_educator_id_fk"
    add_foreign_key "services", "service_types", name: "services_service_type_id_fk"
    add_foreign_key "services", "service_uploads", name: "services_service_upload_id_fk"
    add_foreign_key "services", "students", name: "services_student_id_fk"
    add_foreign_key "student_assessments", "assessments", name: "student_assessments_assessment_id_fk"
    add_foreign_key "student_assessments", "students", name: "student_assessments_student_id_fk"
    add_foreign_key "student_risk_levels", "students", name: "student_risk_levels_student_id_fk"
    add_foreign_key "students", "homerooms", name: "students_homeroom_id_fk"
    add_foreign_key "students", "schools", name: "students_school_id_fk"
  end
end
