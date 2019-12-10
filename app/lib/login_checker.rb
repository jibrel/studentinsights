# Check for suspicious bits about the login, for warning.
class LoginChecker
  def initialize(educator, options = {})
    @educator = educator
    @time_now = options.fetch(:time_now, Time.now)
    @canonical_domain = options.fetch(:canonical_domain, PerDistrict.new.canonical_domain)
  end

  def warn_if_suspicious
    flags = infer_flags
    alert_about(flags)
    flags
  end

  private
  def infer_flags
    last_login_at = LoginActivity.last_login_at(@educator)

    flags = []
    flags << :first_login_month_after_creation if last_login_at.nil? && @educator.created_at < (@time_now - 30.days)
    flags << :first_login_after_six_months if last_login_at.present? && last_login_at < (@time_now - 6.months)
    flags.sort
  end

  def alert_about(flags)
    return if flags.size == 0
    warning_id = SecureRandom.hex(64)

    # alert developer
    with_isolation do
      Rollbar.warn('LoginChecker#warn_if_suspicious', {
        rollbar_safelist_login_flags: flags,
        rollbar_safelist_warning_id: warning_id,
        rollbar_safelist_time_now: @time_now.to_i
      })
    end

    # notify educator via email
    with_isolation do
      send_email_to_user!(@educator.email, warning_id)
    end
  end

  # Isolate alerting so if either fails the other still tries
  def with_isolation(&block)
    begin
      block.call()
    rescue => err
      Rollbar.error("LoginChecker#with_isolation rescued", err)
    end
    nil
  end

  def send_email_to_user!(educator_email, warning_id)
    email_text = user_facing_email_text(warning_id)
    mailgun_helper = MailgunHelper.new
    mailgun_url = mailgun_helper.mailgun_url_from_env(ENV)
    html = mailgun_helper.plain_html_from_text(email_text)
    post_data = Net::HTTP.post_form(URI.parse(mailgun_url), {
      :from => "Student Insights <security@studentinsights.org>",
      :to => educator_email,
      :subject => "Security alert for #{@canonical_domain}",
      :html => html
    })

    # Alert if post to Mailgun failed
    if post_data.code.to_i != 200
      Rollbar.error("LoginChecker#send_email_to_user! failed with post_data.code: #{post_data.code}", {
        rollbar_safelist_warning_id: warning_id,
        rollbar_safelist_time_now: @time_now.to_i
      })
    end
    nil
  end

  # Limit disclosing any other information here
  def user_facing_email_text(warning_id)
    [
      "Your #{@canonical_domain} account was just signed into.  You're getting this email to make sure that it was you.",
      "If this was you, there's nothing else you need to do.",
      "If this wasn't you, your account may have been compromised.  Email security@studentinsights.org and the #{PerDistrict.new.district_name} IT administrator immediately.  They'll take it from there to investigate and protect the students and families in #{PerDistrict.new.district_name}.",
      "",
      "Security alert sent from #{@canonical_domain} at #{@time_now}."
    ].join("\n\n")
  end
end
