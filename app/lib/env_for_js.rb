# typed: true
# This is the data sent down to the JS code in the UI
# Keep in mind that anything here is insecure.
class EnvForJs
  def as_json
    {
      railsEnvironment: Rails.env,
      sessionTimeoutInSeconds: Devise.timeout_in.to_i,
      districtKey: EnvironmentVariable.value('DISTRICT_KEY'),
      shouldReportErrors: EnvironmentVariable.is_true('SHOULD_REPORT_ERRORS'),
      rollbarJsAccessToken: EnvironmentVariable.value('ROLLBAR_JS_ACCESS_TOKEN')
    }
  end
end
