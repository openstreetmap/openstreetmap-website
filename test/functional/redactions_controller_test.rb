require File.dirname(__FILE__) + '/../test_helper'
require 'redactions_controller'

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

  def test_moderators_can_create
    session[:user] = users(:moderator_user).id

    post :create, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :redirect
    assert_redirected_to(redaction_path(Redaction.find_by_title("Foo")))
  end

  def test_non_moderators_cant_create
    session[:user] = users(:public_user).id

    post :create, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :forbidden
  end

  def test_moderators_can_delete_empty
    session[:user] = users(:moderator_user).id

    # remove all elements from the redaction
    redaction = redactions(:example)
    redaction.old_nodes.each     { |n| n.redaction = nil; n.save! }
    redaction.old_ways.each      { |w| w.redaction = nil; w.save! }
    redaction.old_relations.each { |r| r.redaction = nil; r.save! }

    delete :destroy, :id => redaction.id
    assert_response :redirect
    assert_redirected_to(redactions_path)
  end

  def test_moderators_cant_delete_nonempty
    session[:user] = users(:moderator_user).id

    # leave elements in the redaction
    redaction = redactions(:example)

    delete :destroy, :id => redaction.id
    assert_response :redirect
    assert_redirected_to(redaction_path(redaction))
    assert_match /^Redaction is not empty/, flash[:error]
  end

  def test_non_moderators_cant_delete
    session[:user] = users(:public_user).id

    delete :destroy, :id => redactions(:example).id
    assert_response :forbidden
  end

  def test_moderators_can_edit
    session[:user] = users(:moderator_user).id

    get :edit, :id => redactions(:example).id
    assert_response :success
  end

  def test_non_moderators_cant_edit
    session[:user] = users(:public_user).id

    get :edit, :id => redactions(:example).id
    assert_response :redirect
    assert_redirected_to(redactions_path)
  end

  def test_moderators_can_update
    session[:user] = users(:moderator_user).id

    redaction = redactions(:example)

    put :update, :id => redaction.id, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :redirect
    assert_redirected_to(redaction_path(redaction))
  end

  def test_non_moderators_cant_update
    session[:user] = users(:public_user).id

    redaction = redactions(:example)

    put :update, :id => redaction.id, :redaction => { :title => "Foo", :description => "Description here." }
    assert_response :forbidden
  end
end
