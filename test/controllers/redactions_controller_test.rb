require "test_helper"
require "redactions_controller"

class RedactionsControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/redactions", :method => :get },
      { :controller => "redactions", :action => "index" }
    )
    assert_routing(
      { :path => "/redactions/new", :method => :get },
      { :controller => "redactions", :action => "new" }
    )
    assert_routing(
      { :path => "/redactions", :method => :post },
      { :controller => "redactions", :action => "create" }
    )
    assert_routing(
      { :path => "/redactions/1", :method => :get },
      { :controller => "redactions", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/redactions/1/edit", :method => :get },
      { :controller => "redactions", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/redactions/1", :method => :put },
      { :controller => "redactions", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/redactions/1", :method => :delete },
      { :controller => "redactions", :action => "destroy", :id => "1" }
    )
  end

  def test_index
    get :index
    assert_response :success
    assert_template :index
    assert_select "ul#redaction_list", 1 do
      assert_select "li", Redaction.count
    end
  end

  def test_new
    get :new
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_redaction_path)
  end

  def test_new_moderator
    session[:user] = create(:moderator_user).id

    get :new
    assert_response :success
    assert_template :new
  end

  def test_new_non_moderator
    session[:user] = create(:user).id

    get :new
    assert_response :redirect
    assert_redirected_to redactions_path
  end

  def test_create_moderator
    session[:user] = create(:moderator_user).id

    post :create, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :redirect
    assert_redirected_to(redaction_path(Redaction.find_by(:title => "Foo")))
  end

  def test_create_moderator_invalid
    session[:user] = create(:moderator_user).id

    post :create, :redaction => { :title => "Foo", :description => "" }
    assert_response :success
    assert_template :new
  end

  def test_create_non_moderator
    session[:user] = create(:user).id

    post :create, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :forbidden
  end

  def test_destroy_moderator_empty
    session[:user] = create(:moderator_user).id

    # remove all elements from the redaction
    redaction = redactions(:example)
    redaction.old_nodes.each     { |n| n.update!(:redaction => nil) }
    redaction.old_ways.each      { |w| w.update!(:redaction => nil) }
    redaction.old_relations.each { |r| r.update!(:redaction => nil) }

    delete :destroy, :id => redaction.id
    assert_response :redirect
    assert_redirected_to(redactions_path)
  end

  def test_destroy_moderator_non_empty
    session[:user] = create(:moderator_user).id

    # leave elements in the redaction
    redaction = redactions(:example)

    delete :destroy, :id => redaction.id
    assert_response :redirect
    assert_redirected_to(redaction_path(redaction))
    assert_match /^Redaction is not empty/, flash[:error]
  end

  def test_delete_non_moderator
    session[:user] = create(:user).id

    delete :destroy, :id => redactions(:example).id
    assert_response :forbidden
  end

  def test_edit
    get :edit, :id => redactions(:example).id
    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_redaction_path(redactions(:example)))
  end

  def test_edit_moderator
    session[:user] = create(:moderator_user).id

    get :edit, :id => redactions(:example).id
    assert_response :success
  end

  def test_edit_non_moderator
    session[:user] = create(:user).id

    get :edit, :id => redactions(:example).id
    assert_response :redirect
    assert_redirected_to(redactions_path)
  end

  def test_update_moderator
    session[:user] = create(:moderator_user).id

    redaction = redactions(:example)

    put :update, :id => redaction.id, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :redirect
    assert_redirected_to(redaction_path(redaction))
  end

  def test_update_moderator_invalid
    session[:user] = create(:moderator_user).id

    redaction = redactions(:example)

    put :update, :id => redaction.id, :redaction => { :title => "Foo", :description => "" }
    assert_response :success
    assert_template :edit
  end

  def test_updated_non_moderator
    session[:user] = create(:user).id

    redaction = redactions(:example)

    put :update, :id => redaction.id, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :forbidden
  end
end
