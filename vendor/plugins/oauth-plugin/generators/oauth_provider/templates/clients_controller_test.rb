require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../oauth_controller_test_helper'
require 'oauth/client/action_controller_request'

class OauthClientsController; def rescue_action(e) raise e end; end

class OauthClientsControllerIndexTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController
  
  def setup    
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
    
    login_as_application_owner
  end
  
  def do_get
    get :index
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_query_current_users_client_applications
    @user.expects(:client_applications).returns(@client_applications)
    do_get
  end
  
  def test_should_assign_client_applications
    do_get
    assert_equal @client_applications, assigns(:client_applications)
  end
  
  def test_should_render_index_template
    do_get
    assert_template 'index'
  end
end

class OauthClientsControllerShowTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController
  
  def setup
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
    
    login_as_application_owner
  end
  
  def do_get
    get :show, :id=>'3'
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_query_current_users_client_applications
    @user.expects(:client_applications).returns(@client_applications)
    @client_applications.expects(:find).with('3').returns(@client_application)
    do_get
  end
  
  def test_should_assign_client_applications
    do_get
    assert_equal @client_application, assigns(:client_application)
  end
  
  def test_should_render_show_template
    do_get
    assert_template 'show'
  end
  
end

class OauthClientsControllerNewTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController

  def setup
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
    
    login_as_application_owner
    ClientApplication.stubs(:new).returns(@client_application)
  end
  
  def do_get
    get :new
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_assign_client_applications
    do_get
    assert_equal @client_application, assigns(:client_application)
  end
  
  def test_should_render_show_template
    do_get
    assert_template 'new'
  end
  
end
 
class OauthClientsControllerEditTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController
  
  def setup
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    

    login_as_application_owner
  end
  
  def do_get
    get :edit, :id=>'3'
  end
  
  def test_should_be_successful
    do_get
    assert @response.success?
  end
  
  def test_should_query_current_users_client_applications
    @user.expects(:client_applications).returns(@client_applications)
    @client_applications.expects(:find).with('3').returns(@client_application)
    do_get
  end
  
  def test_should_assign_client_applications
    do_get
    assert_equal @client_application, assigns(:client_application)
  end
  
  def test_should_render_edit_template
    do_get
    assert_template 'edit'
  end
  
end

class OauthClientsControllerCreateTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController
  
  def setup
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
    
    login_as_application_owner
    @client_applications.stubs(:build).returns(@client_application)
    @client_application.stubs(:save).returns(true)
  end
  
  def do_valid_post
    @client_application.expects(:save).returns(true)
    post :create,'client_application'=>{'name'=>'my site'}
  end

  def do_invalid_post
    @client_application.expects(:save).returns(false)
    post :create,:client_application=>{:name=>'my site'}
  end
  
  def test_should_query_current_users_client_applications
    @client_applications.expects(:build).returns(@client_application)
    do_valid_post
  end
  
  def test_should_redirect_to_new_client_application
    do_valid_post
    assert_response :redirect
    assert_redirected_to(:action => "show", :id => @client_application.id)
  end
  
  def test_should_assign_client_applications
    do_invalid_post
    assert_equal @client_application, assigns(:client_application)
  end
  
  def test_should_render_show_template
    do_invalid_post
    assert_template('new')
  end
end
 
class OauthClientsControllerDestroyTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController
  
  def setup
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    login_as_application_owner
    @client_application.stubs(:destroy)
  end
  
  def do_delete
    delete :destroy,:id=>'3'
  end
    
  def test_should_query_current_users_client_applications
    @user.expects(:client_applications).returns(@client_applications)
    @client_applications.expects(:find).with('3').returns(@client_application)
    do_delete
  end

  def test_should_destroy_client_applications
    @client_application.expects(:destroy)
    do_delete
  end
    
  def test_should_redirect_to_list
    do_delete
    assert_response :redirect
    assert_redirected_to :action => 'index'
  end
  
end

class OauthClientsControllerUpdateTest < ActionController::TestCase
  include OAuthControllerTestHelper
  tests OauthClientsController

  def setup
    @controller = OauthClientsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as_application_owner
  end
  
  def do_valid_update
    @client_application.expects(:update_attributes).returns(true)
    put :update, :id => '1', 'client_application' => {'name'=>'my site'}
  end

  def do_invalid_update
    @client_application.expects(:update_attributes).returns(false)
    put :update, :id=>'1', 'client_application' => {'name'=>'my site'}
  end
  
  def test_should_query_current_users_client_applications
    @user.expects(:client_applications).returns(@client_applications)
    @client_applications.expects(:find).with('1').returns(@client_application)
    do_valid_update
  end
  
  def test_should_redirect_to_new_client_application
    do_valid_update
    assert_response :redirect
    assert_redirected_to :action => "show", :id => @client_application.id
  end
  
  def test_should_assign_client_applications
    do_invalid_update
    assert_equal @client_application, assigns(:client_application)
  end
  
  def test_should_render_show_template
    do_invalid_update
    assert_template('edit')
  end
end
