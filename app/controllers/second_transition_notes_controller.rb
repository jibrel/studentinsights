class SecondTransitionNotesController < ApplicationController
  before_action :ensure_authorized_to_read!
  before_action :ensure_authorized_to_write!, except: [:restricted_text]

  # post
  def save_json
    ensure_authorized_to_write!
    safe_params = params.permit(*[
      :student_id,
      :second_transition_note_id,
      :starred,
      :restricted_text, {
        form_json: [
          :strengths,
          :connecting,
          :community,
          :peers,
          :other
        ]
      }
    ])
    student_id = safe_params[:student_id]
    id = safe_params[:second_transition_note_id]
    attrs = {
      form_json: safe_params[:form_json],
      starred: safe_params[:starred],
      restricted_text: safe_params[:restricted_text]
    }

    # create or update
    if id.nil?
      authorized_or_raise! { Student.find(student_id) }
      second_transition_note = SecondTransitionNote.create!(attrs.merge({
        educator_id: current_educator.id,
        student_id: student_id,
        form_key: SecondTransitionNote::SOMERVILLE_8TH_TO_9TH_GRADE
      }))
    else
      second_transition_note = verify_authorized_or_raise!(student_id, id)
      second_transition_note.update!(attrs)
    end

    render json: {
      id: second_transition_note.id
    }
  end

  # delete
  def delete_json
    ensure_authorized_to_write!
    safe_params = params.permit(:student_id, :second_transition_note_id)
    second_transition_note = verify_authorized_or_raise!(safe_params[:student_id], safe_params[:second_transition_note_id])

    second_transition_note.destroy!
    render json: { status: 'ok' }
  end

  # get
  def restricted_text
    ensure_authorized_to_read!
    safe_params = params.permit(*[
      :student_id,
      :second_transition_note_id,
    ])
    second_transition_note = verify_authorized_or_raise!(safe_params[:student_id], safe_params[:second_transition_note_id])

    render json: second_transition_note.as_json({
      dangerously_include_restricted_text: true,
      only: [:restricted_text]
    })
  end

  private
  def ensure_authorized_to_read!
    student = Student.find(params[:student_id])
    raise Exceptions::EducatorNotAuthorized unless current_educator.is_authorized_for_student(student)
    raise Exceptions::EducatorNotAuthorized unless current_educator.can_view_restricted_notes
    raise Exceptions::EducatorNotAuthorized unless current_educator.labels.include?('enable_transition_note_features')
  end

  def ensure_authorized_to_write!
    ensure_authorized_to_read!
    raise Exceptions::EducatorNotAuthorized unless current_educator.labels.include?('k8_counselor')
  end

  # Verify authorization for both student and note id
  def verify_authorized_or_raise!(student_id, second_transition_note_id)
    student = authorized_or_raise! { Student.find(student_id) }
    second_transition_note = student.second_transition_notes.find(second_transition_note_id)
    raise Exceptions::EducatorNotAuthorized if second_transition_note.nil?
    raise Exceptions::EducatorNotAuthorized if second_transition_note.student_id != student_id.to_i

    second_transition_note
  end
end
