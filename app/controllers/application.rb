# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  def authorize_web
    @user = User.find_by_token(session[:token])
  end

  def authorize(realm='Web Password', errormessage="Could't authenticate you") 
    username, passwd = get_auth_data 
    # check if authorized 
    # try to get user 
    if @user = User.authenticate(username, passwd) 
      # user exists and password is correct ... horray! 
      if @user.methods.include? 'lastlogin' 
        # note last login 
        @session['lastlogin'] = user.lastlogin 
        @user.last.login = Time.now 
        @user.save() 
        @session["User.id"] = @user.id 
      end             
    else 
      # the user does not exist or the password was wrong 
      @response.headers["Status"] = "Unauthorized" 
      @response.headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\"" 
      render_text(errormessage, 401)
    end 
  end 

  def get_xml_doc
    doc = XML::Document.new
    doc.encoding = 'UTF-8' 
    root = XML::Node.new 'osm'
    root['version'] = API_VERSION
    root['generator'] = 'OpenStreetMap server'
    doc.root = root
    return doc
  end

  private 
  def get_auth_data 
    user, pass = '', '' 
    # extract authorisation credentials 
    if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
      # try to get it where mod_rewrite might have put it 
      authdata = @request.env['X-HTTP_AUTHORIZATION'].to_s.split 
    elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
      # this is the regular location 
      authdata = @request.env['HTTP_AUTHORIZATION'].to_s.split  
    end 

    # at the moment we only support basic authentication 
    if authdata and authdata[0] == 'Basic' 
      user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
    end 
    return [user, pass] 
  end 

end
