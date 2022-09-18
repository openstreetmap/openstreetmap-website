require "test_helper"
require "minitest/mock"

class MicrocosmLinksControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  # Following guidance from Ruby on Rails Guide
  # https://guides.rubyonrails.org/testing.html#functional-tests-for-your-controllers

  def test_routes
    assert_routing(
      { :path => "/microcosms/foo/microcosm_links", :method => :get },
      { :controller => "microcosm_links", :action => "index", :microcosm_id => "foo" }
    )
    assert_routing(
      { :path => "/microcosm_links/1/edit", :method => :get },
      { :controller => "microcosm_links", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/microcosm_links/1", :method => :put },
      { :controller => "microcosm_links", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/microcosms/foo/microcosm_links/new", :method => :get },
      { :controller => "microcosm_links", :action => "new", :microcosm_id => "foo" }
    )
    assert_routing(
      { :path => "/microcosms/foo/microcosm_links", :method => :post },
      { :controller => "microcosm_links", :action => "create", :microcosm_id => "foo" }
    )
  end

  def test_index_get
    # arrange
    m = create(:microcosm)
    link = create(:microcosm_link, :microcosm_id => m.id)
    # act
    get microcosm_microcosm_links_path(m.id)
    # assert
    check_page_basics
    assert_template "index"
    assert_match link.site, response.body
  end

  def test_edit_get_no_session
    # arrange
    l = create(:microcosm_link)
    # act
    get edit_microcosm_link_path(l)
    # assert
    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_microcosm_link_path(l))
  end

  def test_update_as_non_organizer
    # Should this test be in abilities_test.rb?
    # arrange
    link = create(:microcosm_link)
    session_for(create(:user))
    # act
    put microcosm_link_path link, :microcosm_link => link
    # assert
    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_put_success
    # TODO: When microcosm_member is created switch to using that factory.
    # arrange
    m = create(:microcosm)
    link1 = create(:microcosm_link, :microcosm_id => m.id) # original object
    link2 = build(:microcosm_link, :microcosm_id => m.id) # new data
    link_2_form = link2.attributes.except("id", "created_at", "updated_at")
    session_for(m.organizer)

    # act
    # Update m1 with the values from m2.
    put microcosm_link_url(link1), :params => { :microcosm_link => link_2_form.as_json }, :xhr => true

    # assert
    assert_redirected_to microcosm_path(link1.microcosm)
    assert_equal I18n.t("microcosm_links.update.success"), flash[:notice]
    link1.reload
    # Assign the id of link1 to link2, so we can do an equality test easily.
    link2.id = link1.id
    assert_equal(link2, link1)
  end

  def test_update_put_failure
    # arrange
    mic = create(:microcosm) # original object
    session_for(mic.organizer)
    link = create(:microcosm_link, :microcosm_id => mic.id) # original object
    def link.update(_params)
      false
    end

    controller_mock = MicrocosmLinksController.new
    def controller_mock.set_link
      @link = MicrocosmLink.new
    end

    def controller_mock.render(_partial)
      # Can't do assert_equal here.
      # assert_equal :edit, partial
    end

    # act
    MicrocosmLinksController.stub :new, controller_mock do
      MicrocosmLink.stub :new, link do
        assert_difference "MicrocosmLink.count", 0 do
          put microcosm_link_url(link), :params => { :microcosm_link => link.as_json }, :xhr => true
        end
      end
    end

    # assert
    assert_equal I18n.t("microcosm_links.update.failure"), flash[:alert]
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    # arrange
    m = create(:microcosm)
    # act
    get new_microcosm_microcosm_link_path(m)
    # assert
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_microcosm_microcosm_link_path(m))
  end

  def test_new_form
    # Now try again when logged in
    # arrange
    m = create(:microcosm)
    session_for(m.organizer)
    # act
    get new_microcosm_microcosm_link_path(m)
    # assert
    check_page_basics
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /Microcosm Link/, :count => 1
    end
    action = microcosm_microcosm_links_path(m)
    assert_select "div#content", :count => 1 do
      assert_select "form[action='#{action}'][method=post]", :count => 1 do
        assert_select "input#microcosm_link_site[name='microcosm_link[site]']", :count => 1
        assert_select "input#microcosm_link_url[name='microcosm_link[url]']", :count => 1
        assert_select "input", :count => 4
      end
    end
  end

  def test_create_when_save_works
    # arrange
    m = create(:microcosm)
    link_orig = create(:microcosm_link, :microcosm => m)
    form = link_orig.attributes.except("id", "created_at", "updated_at")
    session_for(m.organizer)

    # act
    link_new_id = nil
    assert_difference "MicrocosmLink.count", 1 do
      post microcosm_microcosm_links_path m.id, :microcosm_link => form
      link_new_id = @response.headers["link_id"]
    end

    # assert
    # Not sure what's going on with this assigns magic.
    # assert_redirected_to "/microcosm/#{assigns(:microcosm_link).id}"
    assert_equal I18n.t("microcosm_links.create.success"), flash[:notice]
    link_new = MicrocosmLink.find_by(:id => link_new_id)
    # Assign the id m_new to m_orig, so we can do an equality test easily.
    link_orig.id = link_new.id
    assert_equal(link_orig, link_new)
  end

  def test_create_when_save_fails
    # arrange
    mic = create(:microcosm)
    session_for(mic.organizer)
    link = build(:microcosm_link, :microcosm => mic, :url => "invalid url")
    form = link.attributes.except("id", "created_at", "updated_at")

    # act and assert
    assert_no_difference "MicrocosmLink.count", 0 do
      post microcosm_microcosm_links_path :microcosm_link => form, :microcosm_id => mic.id
    end

    assert_template :new
  end

  def test_delete
    # arrange
    mic = create(:microcosm)
    link = create(:microcosm_link, :microcosm_id => mic.id)
    session_for(mic.organizer)

    # act and assert
    assert_difference "MicrocosmLink.count", -1 do
      delete microcosm_link_path(:id => link.id)
    end
  end
end
