# typed: false

class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # Order matters here a lot.
  protect_from_forgery with: :exception

  force_ssl unless Rails.env.development?

  before_action :redirect_domain!
  before_action :authenticate_educator!  # Devise method, applies to all controllers (in this app 'users' are 'educators')

  rescue_from ActiveRecord::RecordNotFound do
    if request.format.json?
      render_not_found_json!
    elsif request.format.pdf?
      render plain: 'PDF not found', status: 404
    else
      redirect_to home_path
    end
  end

  rescue_from Exceptions::EducatorNotAuthorized do
    if request.format.json?
      render_unauthorized_json!
    elsif request.format.pdf?
      render_unauthorized_plain!
    else
      redirect_unauthorized!
    end
  end

  # This overrides `current_educator` to enable masquerading as other users.
  # It's factored out to be re-used by Administrate, which doesn't inherit
  # from `ApplicationController`.
  include MasqueradeHelpers
  helper_method :masquerade

  # This is a hook that Devise looks for.  We add it here to override
  # Devise's default behavior of storing the last page the user visited,
  # and redirecting them back there after their next sign in.
  # We use our own code here and always navigate to the same page after
  # sign-in.
  #
  # For Devise docs, see https://github.com/plataformatec/devise/blob/40f02ae69baf7e9b0449aaab2aba0d0e166f77a3/lib/devise/controllers/helpers.rb#L188
  def after_sign_in_path_for(educator)
    homepage_path_for_role(educator)
  end

  def homepage_path_for_role(educator)
    home_path # /home
  end

  # Wrap all database queries with this to enforce authorization
  def authorized(&block)
    authorizer.authorized(&block)
  end

  # Enforce authorization and raise if no authorized models
  def authorized_or_raise!(&block)
    return_value = authorizer.authorized(&block)
    if return_value == nil || return_value == []
      raise Exceptions::EducatorNotAuthorized
    end
    return_value
  end

  def render_unauthorized_json!
    Rollbar.error('render_unauthorized_json!')
    render json: { error: 'unauthorized' }, status: 403
  end

  def render_unauthorized_plain!
    Rollbar.error('render_unauthorized_plain!')
    render plain: 'Not authorized', status: 403
  end

  def render_not_found_json!
    Rollbar.error('render_not_found_json!')
    render json: { error: 'not_found' }, status: 404
  end

  # For redirecting requests directly from the Heroku domain to the canonical domain name
  def redirect_domain!
    canonical_domain = PerDistrict.new.canonical_domain
    return if canonical_domain == nil
    return if request.host == canonical_domain
    redirect_to "#{request.protocol}#{canonical_domain}#{request.fullpath}", :status => :moved_permanently
  end

  def redirect_unauthorized!
    redirect_to not_authorized_path
  end

  # Used to wrap a block with timing measurements and logging, returning the value of the
  # block.
  #
  # Example: students = log_timing('load students') { Student.active }
  # Outputs: log_timing:end [load students] 2998ms
  def log_timing(message)
    return_value = nil

    logger.info "log_timing:start [#{message}]"
    timing_ms = Benchmark.ms { return_value = yield }
    logger.info "log_timing:end [#{message}] #{timing_ms.round}ms"

    return_value
  end

  private
  def authorizer
    @authorizer ||= Authorizer.new(current_educator)
  end
end
