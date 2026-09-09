# frozen_string_literal: true

require "test_helper"

class AclsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/acls", :method => :get },
      { :controller => "acls", :action => "index" }
    )
    assert_routing(
      { :path => "/acls/new", :method => :get },
      { :controller => "acls", :action => "new" }
    )
    assert_routing(
      { :path => "/acls", :method => :post },
      { :controller => "acls", :action => "create" }
    )
    assert_routing(
      { :path => "/acls/1/edit", :method => :get },
      { :controller => "acls", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/acls/1", :method => :put },
      { :controller => "acls", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/acls/1", :method => :delete },
      { :controller => "acls", :action => "destroy", :id => "1" }
    )
  end

  def test_index
    get acls_path
    assert_redirected_to login_path(:referer => acls_path)
  end

  def test_index_non_administrator
    session_for(create(:user))

    get acls_path
    assert_redirected_to :controller => "errors", :action => "forbidden"
  end

  def test_index_administrator
    session_for(create(:administrator_user))

    get acls_path
    assert_response :success
    assert_template :index
  end

  def test_new
    get new_acl_path
    assert_redirected_to login_path(:referer => new_acl_path)
  end

  def test_new_non_administrator
    session_for(create(:user))

    get new_acl_path
    assert_redirected_to :controller => "errors", :action => "forbidden"
  end

  def test_new_administrator
    session_for(create(:administrator_user))

    get new_acl_path
    assert_response :success
    assert_template :new
  end

  def test_create
    assert_no_difference "Acl.count" do
      post acls_path(:acl => { :address => "192.0.2.0/24", :k => "no_account_creation" })
    end
    assert_response :forbidden
  end

  def test_create_non_administrator
    session_for(create(:user))

    assert_no_difference "Acl.count" do
      post acls_path(:acl => { :address => "192.0.2.0/24", :k => "no_account_creation" })
    end
    assert_redirected_to :controller => "errors", :action => "forbidden"
  end

  def test_create_administrator
    session_for(create(:administrator_user))

    assert_difference "Acl.count", 1 do
      post acls_path(:acl => { :address => "192.0.2.0/24", :k => "no_account_creation" })
    end
    assert_redirected_to acls_path
  end

  def test_edit
    acl = create(:acl)

    get edit_acl_path(acl)
    assert_redirected_to login_path(:referer => edit_acl_path(acl))
  end

  def test_edit_non_administrator
    session_for(create(:user))

    get edit_acl_path(create(:acl))
    assert_redirected_to :controller => "errors", :action => "forbidden"
  end

  def test_edit_administrator
    session_for(create(:administrator_user))

    get edit_acl_path(create(:acl))
    assert_response :success
    assert_template :edit
  end

  def test_update
    acl = create(:acl, :k => "no_account_creation")

    put acl_path(acl, :acl => { :k => "no_note_comment" })
    assert_response :forbidden
    assert_equal "no_account_creation", acl.reload.k
  end

  def test_update_non_administrator
    session_for(create(:user))
    acl = create(:acl, :k => "no_account_creation")

    put acl_path(acl, :acl => { :k => "no_note_comment" })
    assert_redirected_to :controller => "errors", :action => "forbidden"
    assert_equal "no_account_creation", acl.reload.k
  end

  def test_update_administrator
    session_for(create(:administrator_user))
    acl = create(:acl, :k => "no_account_creation")

    put acl_path(acl, :acl => { :k => "no_note_comment" })
    assert_redirected_to acls_path
    assert_equal "no_note_comment", acl.reload.k
  end

  def test_destroy
    acl = create(:acl)

    assert_no_difference "Acl.count" do
      delete acl_path(acl)
    end
    assert_response :forbidden
  end

  def test_destroy_non_administrator
    session_for(create(:user))
    acl = create(:acl)

    assert_no_difference "Acl.count" do
      delete acl_path(acl)
    end
    assert_redirected_to :controller => "errors", :action => "forbidden"
  end

  def test_destroy_administrator
    session_for(create(:administrator_user))
    acl = create(:acl)

    assert_difference "Acl.count", -1 do
      delete acl_path(acl)
    end
    assert_redirected_to acls_path
  end
end
