# typed: true
# Performs multifactor authentication for either an authenticator app
# or from an OTP send via SMS.  This does not handle provisioning for
# either case, and assumes that is already set.
#
# Note that these have different security and UX profiles (short version:
# authenticator is more secure, but SMS is lower barrier to entry for users).
class MultifactorAuthenticator
  def initialize(educator, options = {})
    @educator = educator
    @logger = options.fetch(:logger, Rails.logger)
    @twilio_client_class = options.fetch(:twilio_client_class, MockTwilioClient.should_use? ? MockTwilioClient : Twilio::REST::Client)
  end

  def is_multifactor_enabled?
    multifactor_config.present?
  end

  # Returns true/false and burns the login_code if it is accepted,
  # returns false if not enabled for the user.
  def is_multifactor_code_valid?(login_code)
    return false unless is_multifactor_enabled?

    # Check the code, enforcing that it comes after the last verification, but
    # allowing 15 seconds of drift if the code hasn't been used yet.
    totp = create_totp!
    verified_password_timestamp = totp.verify(login_code, {
      after: multifactor_config.last_verification_at,
      drift_behind: 15
    })
    return false if verified_password_timestamp.nil?

    # If we authenticated the user, burn the login_code for this time window
    multifactor_config.reload.update!(last_verification_at: Time.at(verified_password_timestamp))
    true
  end

  # If multifactor is enabled, and they are using SMS, send a login code.
  # Otherwise do nothing (eg, they get login code from authenticator app).
  def send_login_code_if_necessary!
    return nil unless is_multifactor_enabled?
    send_login_code_via_sms! if multifactor_config.sms_number.present?
    nil
  end

  private
  def send_login_code_via_sms!
    return nil unless is_multifactor_enabled?
    return nil unless multifactor_config.sms_number.present?

    login_code = get_login_code()
    message_with_login_code = "Sign in code for Student Insights: #{login_code}\n\nIf you did not request this, please reply to let us know so we can secure your account!"
    twilio_message_sid = send_twilio_message!(message_with_login_code, multifactor_config.sms_number)
    @logger.info("MultifactorAuthenticator#send_login_code_via_sms! sent Twilio message, sid:#{twilio_message_sid}")
    nil
  end

  def get_login_code
    totp = create_totp!
    totp.now
  end

  def multifactor_config
    @multifactor_config ||= EducatorMultifactorConfig.find_by(educator_id: @educator.id)
  end

  ### totp
  # Create a TOTP for this educator
  def create_totp!
    rotp_secret = validated_rotp_secret_for_educator!
    rotp_config = validated_rotp_config!(ENV)
    issuer = [rotp_config['issuer_base'], PerDistrict.new.district_key].join('-')
    ROTP::TOTP.new(rotp_secret, issuer: issuer)
  end

  def validated_rotp_secret_for_educator!
    rotp_secret = multifactor_config.rotp_secret
    raise Exceptions::InvalidConfiguration if rotp_secret.nil?
    rotp_secret
  end

  def validated_rotp_config!(env)
    rotp_config = JSON.parse(env.fetch('MULTIFACTOR_AUTHENTICATOR_ROTP_CONFIG_JSON', '{}'))
    raise Exceptions::InvalidConfiguration if rotp_config['issuer_base'].nil?
    rotp_config
  end

  # private, for one-off console use only
  def enable_multifactor!
    EducatorMultifactorConfig.create!({
      educator: @educator,
      rotp_secret: EducatorMultifactorConfig.new_rotp_secret,
      last_verification_at: nil
    })
  end

  # private, for one-off console use only
  # Returns a string of ANSI rendering of a QR code, used for provisioning
  # an MFA authenticator app with the educator's ROTP secret.
  def provision
    return nil unless is_multifactor_enabled?

    totp = create_totp!
    name_within_authenticator_app = "Student Insights #{PerDistrict.new.district_name}"
    url = totp.provisioning_uri(name_within_authenticator_app)
    RQRCode::QRCode.new(url).as_ansi({
      light: "\033[47m",
      dark: "\033[40m",
      fill_character: '  ',
      quiet_zone_size: 4
    })
  end

  ### twilio

  def send_twilio_message!(message, to_sms_number)
    twilio_config = validated_twilio_config!(ENV)
    client = @twilio_client_class.new(twilio_config['account_sid'], twilio_config['auth_token'])
    twilio_message = client.messages.create({
      body: message,
      to: to_sms_number,
      from: twilio_config['sending_number']
    })
    twilio_message.try(:sid)
  end

  def validated_twilio_config!(env)
    twilio_config = JSON.parse(env.fetch('TWILIO_CONFIG_JSON', '{}'))
    raise Exceptions::InvalidConfiguration if twilio_config['account_sid'].nil?
    raise Exceptions::InvalidConfiguration if twilio_config['auth_token'].nil?
    raise Exceptions::InvalidConfiguration if twilio_config['sending_number'].nil?
    raise Exceptions::InvalidConfiguration if twilio_config['sending_number'].match(/\A\+1\d{10}\z/).nil?
    twilio_config
  end
end
