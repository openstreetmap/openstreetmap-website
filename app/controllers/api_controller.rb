class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  private

  ##
  # Set allowed request formats if no explicit format has been
  # requested via a URL suffix. Allowed formats are taken from
  # any HTTP Accept header with XML as the default.
  def set_request_formats
    unless params[:format]
      accept_header = request.headers["HTTP_ACCEPT"]

      if accept_header
        # Some clients (such asJOSM) send Accept headers which cannot be
        # parse by Rails, for example:
        #
        #   Accept: text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2
        #
        # where both "*" and ".2" as a quality do not adhere to the syntax
        # described in RFC 7231, section 5.3.1, etc.
        #
        # As a workaround, and for back compatibility, default to XML format.
        mimetypes = begin
          Mime::Type.parse(accept_header)
        rescue Mime::Type::InvalidMimeType
          Array(Mime[:xml])
        end

        # Allow XML and JSON formats, and treat an all formats wildcard
        # as XML for backwards compatibility - all other formats are discarded
        # which will result in a 406 Not Acceptable response being sent
        formats = mimetypes.map do |mime|
          if mime.symbol == :xml || mime == "*/*" then :xml
          elsif mime.symbol == :json then :json
          end
        end
      else
        # Default to XML if no accept header was sent - this includes
        # the unit tests which don't set one by default
        formats = Array(:xml)
      end

      request.formats = formats.compact
    end
  end

  def authorize(realm = "Web Password", errormessage = "Couldn't authenticate you")
    # make the current_user object from any auth sources we have
    setup_user_auth

    # handle authenticate pass/fail
    unless current_user
      # no auth, the user does not exist or the password was wrong
      if Settings.basic_auth_support
        response.headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\""
        render :plain => errormessage, :status => :unauthorized
      else
        render :plain => errormessage, :status => :forbidden
      end

      false
    end
  end

  def current_ability
    # Use capabilities from the oauth token if it exists and is a valid access token
    if doorkeeper_token&.accessible?
      ApiAbility.new(nil).merge(ApiCapability.new(doorkeeper_token))
    elsif Authenticator.new(self, [:token]).allow?
      ApiAbility.new(nil).merge(ApiCapability.new(current_token))
    else
      ApiAbility.new(current_user)
    end
  end

  def deny_access(_exception)
    if doorkeeper_token || current_token
      set_locale
      report_error t("oauth.permissions.missing"), :forbidden
    elsif current_user
      head :forbidden
    elsif Settings.basic_auth_support
      realm = "Web Password"
      errormessage = "Couldn't authenticate you"
      response.headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\""
      render :plain => errormessage, :status => :unauthorized
    else
      render :plain => errormessage, :status => :forbidden
    end
  end

  def gpx_status
    status = database_status
    status = "offline" if status == "online" && Settings.status == "gpx_offline"
    status
  end

  ##
  # sets up the current_user for use by other methods. this is mostly called
  # from the authorize method, but can be called elsewhere if authorisation
  # is optional.
  def setup_user_auth
    logger.info " setup_user_auth"
    # try and setup using OAuth
    if doorkeeper_token&.accessible?
      self.current_user = User.find(doorkeeper_token.resource_owner_id)
    elsif Authenticator.new(self, [:token]).allow?
      # self.current_user setup by OAuth
    elsif Settings.basic_auth_support
      username, passwd = auth_data # parse from headers
      # authenticate per-scheme
      self.current_user = if username.nil?
                            nil # no authentication provided - perhaps first connect (client should retry after 401)
                          elsif username == "token"
                            User.authenticate(:token => passwd) # preferred - random token for user from db, passed in basic auth
                          else
                            User.authenticate(:username => username, :password => passwd) # basic auth
                          end
      # log if we have authenticated using basic auth
      logger.info "Authenticated as user #{current_user.id} using basic authentication" if current_user
    end

    # have we identified the user?
    if current_user
      # check if the user has been banned
      user_block = current_user.blocks.active.take
      unless user_block.nil?
        set_locale
        if user_block.zero_hour?
          report_error t("application.setup_user_auth.blocked_zero_hour"), :forbidden
        else
          report_error t("application.setup_user_auth.blocked"), :forbidden
        end
      end

      # if the user hasn't seen the contributor terms then don't
      # allow editing - they have to go to the web site and see
      # (but can decline) the CTs to continue.
      if !current_user.terms_seen && flash[:skip_terms].nil?
        set_locale
        report_error t("application.setup_user_auth.need_to_see_terms"), :forbidden
      end
    end
  end
end
