# typed: false
require 'spec_helper'

RSpec.describe Masquerade do
  let!(:pals) { TestPals.create! }
  let!(:not_allowed_educators) { Educator.all - [pals.uri] }

  # None of these methods should touch anything on the session other
  # than one particular key that this class owns, so this is for testing
  # that.
  def create_session
    {
      'some_other_devise_key_that_should_not_be_touched' => 'foo'
    }
  end

  def create_masquerade(underlying_current_educator)
    session = create_session
    masquerade = Masquerade.new(session, lambda { underlying_current_educator })
    [session, masquerade]
  end

  describe '#authorized?' do
    it 'allows Uri' do
      session, masquerade = create_masquerade(pals.uri)
      expect(masquerade.authorized?).to eq true
    end

    it 'does not allow any other educators' do
      not_allowed_educators.each do |not_allowed_educator|
        session, masquerade = create_masquerade(not_allowed_educator)
        expect(masquerade.authorized?).to eq false
      end
    end

    it 'respects ENV kill switch' do
      session, masquerade = create_masquerade(pals.uri)
      expect(masquerade.authorized?).to eq true
      allow(EnvironmentVariable).to receive(:is_true).with('ENABLE_MASQUERADING').and_return false
      expect(masquerade.is_masquerading?).to eq false
    end
  end

  describe '#is_masquerading?' do
    it 'can tell when masquerading' do
      session, masquerade = create_masquerade(pals.uri)
      masquerade.become_educator_id!(pals.shs_jodi.id)
      expect(masquerade.is_masquerading?).to eq true
    end

    it 'can tell when not masquerading' do
      session, masquerade = create_masquerade(pals.uri)
      expect(masquerade.is_masquerading?).to eq false
    end

    it 'checks what is expected for various values' do
      session, masquerade = create_masquerade(pals.uri)
      session.delete('masquerade.masquerading_educator_id')
      expect(masquerade.is_masquerading?).to eq(false)
      session['masquerade.masquerading_educator_id'] = false
      expect(masquerade.is_masquerading?).to eq(true)
      session.delete('masquerade.masquerading_educator_id')
      expect(masquerade.is_masquerading?).to eq(false)
      session['masquerade.masquerading_educator_id'] = 'whatever'
      expect(masquerade.is_masquerading?).to eq(true)
    end

    it 'respects ENV kill switch' do
      session, masquerade = create_masquerade(pals.uri)
      masquerade.become_educator_id!(pals.shs_jodi.id)
      expect(masquerade.is_masquerading?).to eq true
      allow(EnvironmentVariable).to receive(:is_true).with('ENABLE_MASQUERADING').and_return false
      expect(masquerade.is_masquerading?).to eq(false)
    end
  end

  describe '#become_educator_id!' do
    def expect_masquerading_to_succeed(educator, target_educator)
      session, masquerade = create_masquerade(educator)
      expect(masquerade.become_educator_id!(target_educator.id)).to eq nil
      expect(session['masquerade.masquerading_educator_id']).to eq target_educator.id
      expect(masquerade.is_masquerading?).to eq true
      expect(masquerade.current_educator).to eq target_educator
    end

    def expect_masquerading_to_fail(educator, target_educator)
      session, masquerade = create_masquerade(educator)
      before_session = session.as_json
      expect { masquerade.become_educator_id!(target_educator.id) }.to raise_error Exceptions::EducatorNotAuthorized
      expect(session.as_json).to eq(before_session)
    end

    it 'raises for all combinations of educators, without changing session' do
      not_allowed_educators.each do |not_allowed_educator|
        ([pals.uri] + not_allowed_educators).each do |target_educator|
          expect_masquerading_to_fail(not_allowed_educator, target_educator)
        end
      end
    end

    it 'raise if already masquerading as someone else' do
      session, masquerade = create_masquerade(pals.uri)
      masquerade.become_educator_id!(pals.shs_jodi.id)
      expect(session['masquerade.masquerading_educator_id']).to eq pals.shs_jodi.id

      expect { masquerade.become_educator_id!(pals.healey_sarah_teacher.id) }.to raise_error Exceptions::EducatorNotAuthorized
      expect(session['masquerade.masquerading_educator_id']).to eq pals.shs_jodi.id
    end

    it 'raise if an educator tries to become themselves' do
      expect_masquerading_to_fail(pals.uri, pals.uri)
    end

    it 'allows Uri to become any other educator' do
      not_allowed_educators.each do |target_educator|
        expect_masquerading_to_succeed(pals.uri, target_educator)
      end
    end

    it 'logs a record of the operation' do
      expect(MasqueradingLog.all.size).to eq 0
      expect_masquerading_to_succeed(pals.uri, pals.shs_jodi)
      expect(MasqueradingLog.all.size).to eq 1
      expect(MasqueradingLog.last.as_json.slice('action', 'educator_id', 'masquerading_as_educator_id')).to eq({
        "action" => "become",
        "educator_id" => pals.uri.id,
        "masquerading_as_educator_id" => pals.shs_jodi.id,
      })
    end
  end

  describe '#clear!' do
    it 'raises for all combinations of educators, without changing session' do
      not_allowed_educators.each do |not_allowed_educator|
        session, masquerade = create_masquerade(not_allowed_educator)
        before_session = session.as_json
        expect { masquerade.clear! }.to raise_error Exceptions::EducatorNotAuthorized
        expect(session).to eq before_session
      end
    end

    it 'works as expected internally' do
      session, masquerade = create_masquerade(pals.uri)
      before_session = session.as_json
      masquerade.become_educator_id!(pals.shs_jodi.id)
      expect(session['masquerade.masquerading_educator_id']).to eq pals.shs_jodi.id

      expect(masquerade.clear!).to eq nil
      expect(session.has_key?('masquerade.masquerading_educator_id')).to eq false
      expect(session).to eq before_session
    end

    it 'allows Uri to clear' do
      session, masquerade = create_masquerade(pals.uri)
      masquerade.become_educator_id!(pals.shs_jodi.id)
      expect(session['masquerade.masquerading_educator_id']).to eq pals.shs_jodi.id
      expect(masquerade.clear!).to eq nil
      expect(masquerade.is_masquerading?).to eq false
      expect { masquerade.current_educator }.to raise_error Exceptions::EducatorNotAuthorized
    end

    it 'logs a record of the operation' do
      expect(MasqueradingLog.all.size).to eq 0
      session, masquerade = create_masquerade(pals.uri)
      masquerade.become_educator_id!(pals.shs_jodi.id)
      masquerade.clear!
      expect(MasqueradingLog.all.size).to eq 2
      expect(MasqueradingLog.last.as_json.slice('action', 'educator_id', 'masquerading_as_educator_id')).to eq({
        "action" => "clear",
        "educator_id" => pals.uri.id,
        "masquerading_as_educator_id" => pals.shs_jodi.id,
      })
    end
  end

  describe '#current_educator' do
    it 'raises for all combinations of educators' do
      not_allowed_educators.each do |not_allowed_educator|
        session, masquerade = create_masquerade(not_allowed_educator)
        expect { masquerade.current_educator }.to raise_error Exceptions::EducatorNotAuthorized
      end
    end

    it 'raises if not masquerading' do
      session, masquerade = create_masquerade(pals.uri)
      expect { masquerade.current_educator }.to raise_error Exceptions::EducatorNotAuthorized
      masquerade.clear!
      expect { masquerade.current_educator }.to raise_error Exceptions::EducatorNotAuthorized
    end

    it 'allows Uri to be any educator' do
      not_allowed_educators.each do |target_educator|
        session, masquerade = create_masquerade(pals.uri)
        masquerade.become_educator_id!(target_educator.id)
        expect(masquerade.current_educator).to eq target_educator
      end
    end
  end
end
