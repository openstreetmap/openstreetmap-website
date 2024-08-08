require "test_helper"
require "minitest/mock"

class CommunityLinksControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  # Following guidance from Ruby on Rails Guide
  # https://guides.rubyonrails.org/testing.html#functional-tests-for-your-controllers

  def test_routes
    assert_routing(
      { :path => "/communities/foo/community_links", :method => :get },
      { :controller => "community_links", :action => "index", :community_id => "foo" }
    )
    assert_routing(
      { :path => "/community_links/1/edit", :method => :get },
      { :controller => "community_links", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/community_links/1", :method => :put },
      { :controller => "community_links", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/communities/foo/community_links/new", :method => :get },
      { :controller => "community_links", :action => "new", :community_id => "foo" }
    )
    assert_routing(
      { :path => "/communities/foo/community_links", :method => :post },
      { :controller => "community_links", :action => "create", :community_id => "foo" }
    )
  end

  def test_index_get
    c = create(:community)
    link = create(:community_link, :community_id => c.id)

    get community_community_links_path(c.id)

    assert_response :success
    assert_template "index"
    assert_match link.text, response.body
  end

  def test_edit_get_no_session
    link = create(:community_link)

    get edit_community_link_path(link)

    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_community_link_path(link))
  end

  def test_update_as_non_organizer
    # Should this test be in abilities_test.rb?
    link = create(:community_link)
    session_for(create(:user))

    put community_link_path link, :community_link => link

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_put_success
    # TODO: When community_member is created switch to using that factory.
    c = create_community_with_organizer
    link1 = create(:community_link, :community_id => c.id) # original object
    link2 = build(:community_link, :community_id => c.id) # new data
    link_2_form = link2.attributes.except("id", "created_at", "updated_at")
    session_for(c.leader)

    # Update link1 with the values from link2.
    put community_link_url(link1), :params => { :community_link => link_2_form.as_json }, :xhr => true

    assert_redirected_to community_path(link1.community)
    assert_equal I18n.t("community_links.update.success"), flash[:notice]
    link1.reload
    # Assign the id of link1 to link2, so we can do an equality test easily.
    link2.id = link1.id
    assert_equal(link2, link1)
  end

  def test_update_put_failure
    c = create_community_with_organizer
    session_for(c.leader)
    link = create(:community_link, :community_id => c.id)
    def link.update(_params)
      false
    end

    controller_mock = CommunityLinksController.new
    def controller_mock.set_link
      @link = CommunityLink.new
    end

    def controller_mock.render(_partial)
      # Can't do assert_equal here.
      # assert_equal :edit, partial
    end

    CommunityLinksController.stub :new, controller_mock do
      CommunityLink.stub :new, link do
        assert_difference "CommunityLink.count", 0 do
          put community_link_url(link), :params => { :community_link => link.as_json }, :xhr => true
        end
      end
    end

    assert_equal I18n.t("community_links.update.failure"), flash[:alert]
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    c = create(:community)

    get new_community_community_link_path(c)

    assert_response :redirect
    assert_redirected_to login_path(:referer => new_community_community_link_path(c))
  end

  def test_new_form
    # Now try again when logged in
    c = create(:community)
    session_for(c.leader)

    get new_community_community_link_path(c)

    assert_response :success
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /Community Link/, :count => 1
    end
    action = community_community_links_path(c)
    assert_select "div#content", :count => 1 do
      assert_select "form[action='#{action}'][method=post]", :count => 1 do
        assert_select "input#community_link_text[name='community_link[text]']", :count => 1
        assert_select "input#community_link_url[name='community_link[url]']", :count => 1
        assert_select "input", :count => 3
      end
    end
  end

  def test_create_when_save_works
    c = create(:community)
    link_orig = create(:community_link, :community => c)
    form = link_orig.attributes.except("id", "created_at", "updated_at")
    session_for(c.leader)

    link_new_id = nil
    assert_difference "CommunityLink.count", 1 do
      post community_community_links_path c.id, :community_link => form
      link_new_id = @response.headers["link_id"]
    end

    # Not sure what's going on with this assigns magic.
    # assert_redirected_to "/community/#{assigns(:community_link).id}"
    assert_equal I18n.t("community_links.create.success"), flash[:notice]
    link_new = CommunityLink.find_by(:id => link_new_id)
    # Assign the id link_new to link_orig, so we can do an equality test easily.
    link_orig.id = link_new.id
    assert_equal(link_orig, link_new)
  end

  def test_create_when_save_fails
    c = create(:community)
    session_for(c.leader)
    link = build(:community_link, :community => c, :url => "invalid url")
    form = link.attributes.except("id", "created_at", "updated_at")

    assert_no_difference "CommunityLink.count", 0 do
      post community_community_links_path :community_link => form, :community_id => c.id
    end

    assert_template :new
  end

  def test_delete
    c = create_community_with_organizer
    link = create(:community_link, :community_id => c.id)
    session_for(c.leader)

    assert_difference "CommunityLink.count", -1 do
      delete community_link_path(:id => link.id)
    end
  end
end
