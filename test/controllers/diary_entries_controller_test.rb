require "test_helper"

class DiaryEntriesControllerTest < ActionDispatch::IntegrationTest
  include ActionView::Helpers::NumberHelper

  def setup
    super
    # Create the default language for diary entries
    create(:language, :code => "en")
    # Stub nominatim response for diary entry locations
    stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
      .to_return(:status => 404)
  end

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/diary", :method => :get },
      { :controller => "diary_entries", :action => "index" }
    )
    assert_routing(
      { :path => "/diary/language", :method => :get },
      { :controller => "diary_entries", :action => "index", :language => "language" }
    )
    assert_routing(
      { :path => "/user/username/diary", :method => :get },
      { :controller => "diary_entries", :action => "index", :display_name => "username" }
    )
    assert_routing(
      { :path => "/diary/friends", :method => :get },
      { :controller => "diary_entries", :action => "index", :friends => true }
    )
    assert_routing(
      { :path => "/diary/nearby", :method => :get },
      { :controller => "diary_entries", :action => "index", :nearby => true }
    )

    assert_routing(
      { :path => "/diary/rss", :method => :get },
      { :controller => "diary_entries", :action => "rss", :format => :rss }
    )
    assert_routing(
      { :path => "/diary/language/rss", :method => :get },
      { :controller => "diary_entries", :action => "rss", :language => "language", :format => :rss }
    )
    assert_routing(
      { :path => "/user/username/diary/rss", :method => :get },
      { :controller => "diary_entries", :action => "rss", :display_name => "username", :format => :rss }
    )

    assert_routing(
      { :path => "/diary/new", :method => :get },
      { :controller => "diary_entries", :action => "new" }
    )
    assert_routing(
      { :path => "/diary", :method => :post },
      { :controller => "diary_entries", :action => "create" }
    )
    assert_routing(
      { :path => "/user/username/diary/1", :method => :get },
      { :controller => "diary_entries", :action => "show", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/edit", :method => :get },
      { :controller => "diary_entries", :action => "edit", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1", :method => :put },
      { :controller => "diary_entries", :action => "update", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/hide", :method => :post },
      { :controller => "diary_entries", :action => "hide", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/unhide", :method => :post },
      { :controller => "diary_entries", :action => "unhide", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/subscribe", :method => :get },
      { :controller => "diary_entries", :action => "subscribe", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/subscribe", :method => :post },
      { :controller => "diary_entries", :action => "subscribe", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/unsubscribe", :method => :get },
      { :controller => "diary_entries", :action => "unsubscribe", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/unsubscribe", :method => :post },
      { :controller => "diary_entries", :action => "unsubscribe", :display_name => "username", :id => "1" }
    )
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    get new_diary_entry_path
    assert_redirected_to login_path(:referer => "/diary/new")
  end

  def test_new_form
    # Now try again when logged in
    session_for(create(:user))
    get new_diary_entry_path
    assert_response :success
    assert_select "title", :text => /New Diary Entry/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /New Diary Entry/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/diary'][method=post]", :count => 1 do
        assert_select "input#diary_entry_title[name='diary_entry[title]']", :count => 1
        assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :text => "", :count => 1
        assert_select "select#diary_entry_language_code", :count => 1
        assert_select "input#latitude[name='diary_entry[latitude]']", :count => 1
        assert_select "input#longitude[name='diary_entry[longitude]']", :count => 1
        assert_select "input[name=commit][type=submit][value=Publish]", :count => 1
        assert_select "button[type=button]", :text => "Edit", :count => 1
        assert_select "button[type=button]", :text => "Preview", :count => 1
        assert_select "input", :count => 4
      end
    end
  end

  def test_new_get_with_params
    # Now try creating a diary entry using get
    session_for(create(:user))
    assert_difference "DiaryEntry.count", 0 do
      get new_diary_entry_path(:diary_entry => { :title => "New Title", :body => "This is a new body for the diary entry", :latitude => "1.1",
                                                 :longitude => "2.2", :language_code => "en" })
    end
    assert_response :success
    assert_template :new
  end

  def test_create_no_body
    # Now try creating a invalid diary entry with an empty body
    user = create(:user)
    session_for(user)
    assert_no_difference "DiaryEntry.count" do
      post diary_entries_path(:diary_entry => { :title => "New Title", :body => "", :latitude => "1.1",
                                                :longitude => "2.2", :language_code => "en" })
    end
    assert_response :success
    assert_template :new

    assert_nil UserPreference.find_by(:user => user, :k => "diary.default_language")
  end

  def test_create
    # Now try creating a diary entry
    user = create(:user)
    session_for(user)
    assert_difference "DiaryEntry.count", 1 do
      post diary_entries_path(:diary_entry => { :title => "New Title", :body => "This is a new body for the diary entry", :latitude => "1.1",
                                                :longitude => "2.2", :language_code => "en" })
    end
    entry = DiaryEntry.last
    assert_redirected_to diary_entry_path(user, entry)
    assert_equal user.id, entry.user_id
    assert_equal "New Title", entry.title
    assert_equal "This is a new body for the diary entry", entry.body
    assert_equal "1.1".to_f, entry.latitude
    assert_equal "2.2".to_f, entry.longitude
    assert_equal "en", entry.language_code

    # checks if user was subscribed
    assert_equal 1, entry.subscribers.length

    assert_equal "en", UserPreference.find_by(:user => user, :k => "diary.default_language").v
  end

  def test_create_german
    create(:language, :code => "de")
    user = create(:user)
    session_for(user)

    # Now try creating a diary entry in a different language
    assert_difference "DiaryEntry.count", 1 do
      post diary_entries_path(:diary_entry => { :title => "New Title", :body => "This is a new body for the diary entry", :latitude => "1.1",
                                                :longitude => "2.2", :language_code => "de" })
    end
    entry = DiaryEntry.last
    assert_redirected_to diary_entry_path(user, entry)
    assert_equal user.id, entry.user_id
    assert_equal "New Title", entry.title
    assert_equal "This is a new body for the diary entry", entry.body
    assert_equal "1.1".to_f, entry.latitude
    assert_equal "2.2".to_f, entry.longitude
    assert_equal "de", entry.language_code

    # checks if user was subscribed
    assert_equal 1, entry.subscribers.length

    assert_equal "de", UserPreference.find_by(:user => user, :k => "diary.default_language").v
  end

  def test_new_spammy
    user = create(:user)
    session_for(user)

    # Generate some spammy content
    spammy_title = "Spam Spam Spam Spam Spam"
    spammy_body = 1.upto(50).map { |n| "http://example.com/spam#{n}" }.join(" ")

    # Try creating a spammy diary entry
    assert_difference "DiaryEntry.count", 1 do
      post diary_entries_path(:diary_entry => { :title => spammy_title, :body => spammy_body, :language_code => "en" })
    end
    entry = DiaryEntry.last
    assert_redirected_to diary_entry_path(user, entry)
    assert_equal user.id, entry.user_id
    assert_equal spammy_title, entry.title
    assert_equal spammy_body, entry.body
    assert_equal "en", entry.language_code
    assert_equal "suspended", User.find(user.id).status

    # Follow the redirect
    get diary_entries_path(:display_name => user.display_name)
    assert_redirected_to :controller => :users, :action => :suspended
  end

  def test_edit
    user = create(:user)
    other_user = create(:user)

    entry = create(:diary_entry, :user => user)

    # Make sure that you are redirected to the login page when you are
    # not logged in, without and with the id of the entry you want to edit
    get edit_diary_entry_path(entry.user, entry)
    assert_redirected_to login_path(:referer => "/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}/edit")

    session_for(other_user)

    # Verify that you get redirected to show if you are not the user
    # that created the entry
    get edit_diary_entry_path(entry.user, entry)
    assert_redirected_to :action => :show, :display_name => entry.user.display_name, :id => entry.id

    session_for(entry.user)

    # Verify that you get a not found error, when you pass a bogus id
    get edit_diary_entry_path(entry.user, :id => 9999)
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => "No entry with the id: 9999", :count => 1
    end

    # Now pass the id, and check that you can edit it, when using the same
    # user as the person who created the entry
    get edit_diary_entry_path(entry.user, entry)
    assert_response :success
    assert_select "title", :text => /Edit Diary Entry/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /Edit Diary Entry/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}'][method=post]", :count => 1 do
        assert_select "input#diary_entry_title[name='diary_entry[title]'][value='#{entry.title}']", :count => 1
        assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :text => entry.body, :count => 1
        assert_select "select#diary_entry_language_code", :count => 1
        assert_select "input#latitude[name='diary_entry[latitude]']", :count => 1
        assert_select "input#longitude[name='diary_entry[longitude]']", :count => 1
        assert_select "input[name=commit][type=submit][value=Update]", :count => 1
        assert_select "button[type=button]", :text => "Edit", :count => 1
        assert_select "button[type=button]", :text => "Preview", :count => 1
        assert_select "input", :count => 5
      end
    end

    # Now lets see if you can edit the diary entry
    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    new_language_code = "en"
    put diary_entry_path(entry.user, entry, :diary_entry => { :title => new_title, :body => new_body, :latitude => new_latitude,
                                                              :longitude => new_longitude, :language_code => new_language_code })
    assert_redirected_to :action => :show, :display_name => entry.user.display_name, :id => entry.id

    # Now check that the new data is rendered, when logged in
    get diary_entry_path(entry.user, entry)
    assert_response :success
    assert_template "show"
    assert_select "title", :text => /Users' Diaries | /, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /#{entry.user.display_name}'s Diary/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "h2", :text => /#{new_title}/, :count => 1
      # This next line won't work if the text has been run through the htmlize function
      # due to formatting that could be introduced
      assert_select "p", :text => /#{new_body}/, :count => 1
      assert_select "abbr[class='geo'][title='#{number_with_precision(new_latitude, :precision => 4)}; #{number_with_precision(new_longitude, :precision => 4)}']", :count => 1
      # As we're not logged in, check that you cannot edit
      assert_select "a[href='/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}/edit']", :text => "Edit this entry", :count => 1
    end

    # and when not logged in as the user who wrote the entry
    session_for(create(:user))
    get diary_entry_path(entry.user, entry)
    assert_response :success
    assert_template "show"
    assert_select "title", :text => /Users' Diaries | /, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /#{entry.user.display_name}'s Diary/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "h2", :text => /#{new_title}/, :count => 1
      # This next line won't work if the text has been run through the htmlize function
      # due to formatting that could be introduced
      assert_select "p", :text => /#{new_body}/, :count => 1
      assert_select "abbr[class=geo][title='#{number_with_precision(new_latitude, :precision => 4)}; #{number_with_precision(new_longitude, :precision => 4)}']", :count => 1
      # As we're not logged in, check that you cannot edit
      assert_select "a[href='/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}/edit']", false
    end
  end

  def test_edit_i18n
    user = create(:user)
    diary_entry = create(:diary_entry, :language_code => "en", :user => user)
    session_for(user)
    get edit_diary_entry_path(user, diary_entry)
    assert_response :success
    assert_select "span[class=translation_missing]", false, "Missing translation in edit diary entry"
  end

  def test_update
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :language_code => "en", :user => user, :title => "Original Title")

    put diary_entry_path(user, diary_entry, :diary_entry => { :title => "Updated Title" })
    assert_response :forbidden
    diary_entry.reload
    assert_equal "Original Title", diary_entry.title

    session_for(other_user)
    put diary_entry_path(user, diary_entry, :diary_entry => { :title => "Updated Title" })
    assert_redirected_to diary_entry_path(user, diary_entry)
    diary_entry.reload
    assert_equal "Original Title", diary_entry.title

    session_for(user)
    put diary_entry_path(user, diary_entry, :diary_entry => { :title => "Updated Title" })
    assert_redirected_to diary_entry_path(user, diary_entry)
    diary_entry.reload
    assert_equal "Updated Title", diary_entry.title
  end

  def test_index_all
    diary_entry = create(:diary_entry)
    geo_entry = create(:diary_entry, :latitude => 51.50763, :longitude => -0.10781)
    public_entry = create(:diary_entry, :user => create(:user))

    # Try a list of all diary entries
    get diary_entries_path
    check_diary_index diary_entry, geo_entry, public_entry
  end

  def test_index_user
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)
    geo_entry = create(:diary_entry, :user => user, :latitude => 51.50763, :longitude => -0.10781)
    _other_entry = create(:diary_entry, :user => other_user)

    # Try a list of diary entries for a valid user
    get diary_entries_path(:display_name => user.display_name)
    check_diary_index diary_entry, geo_entry

    # Try a list of diary entries for an invalid user
    get diary_entries_path(:display_name => "No Such User")
    assert_response :not_found
    assert_template "users/no_such_user"
  end

  def test_index_friends
    user = create(:user)
    other_user = create(:user)
    follow = create(:follow, :follower => user)
    diary_entry = create(:diary_entry, :user => follow.following)
    _other_entry = create(:diary_entry, :user => other_user)

    # Try a list of diary entries for your friends when not logged in
    get friends_diary_entries_path
    assert_redirected_to login_path(:referer => "/diary/friends")

    # Try a list of diary entries for your friends when logged in
    session_for(user)
    get friends_diary_entries_path
    check_diary_index diary_entry
    session_for(other_user)
    get friends_diary_entries_path
    check_diary_index
  end

  def test_index_nearby
    user = create(:user, :home_lat => 12, :home_lon => 12)
    nearby_user = create(:user, :home_lat => 11.9, :home_lon => 12.1)

    diary_entry = create(:diary_entry, :user => user)

    # Try a list of diary entries for nearby users when not logged in
    get nearby_diary_entries_path
    assert_redirected_to login_path(:referer => "/diary/nearby")

    # Try a list of diary entries for nearby users when logged in
    session_for(nearby_user)
    get nearby_diary_entries_path
    check_diary_index diary_entry
    session_for(user)
    get nearby_diary_entries_path
    check_diary_index
  end

  def test_index_language
    create(:language, :code => "de")
    create(:language, :code => "sl")
    diary_entry_en = create(:diary_entry, :language_code => "en")
    diary_entry_en2 = create(:diary_entry, :language_code => "en")
    diary_entry_de = create(:diary_entry, :language_code => "de")

    # Try a list of diary entries in english
    get diary_entries_path(:language => "en")
    check_diary_index diary_entry_en, diary_entry_en2

    # Try a list of diary entries in german
    get diary_entries_path(:language => "de")
    check_diary_index diary_entry_de

    # Try a list of diary entries in slovenian
    get diary_entries_path(:language => "sl")
    check_diary_index
  end

  def test_index_paged
    # Create several pages worth of diary entries
    create_list(:diary_entry, 50)

    # Try and get the index
    get diary_entries_path
    assert_response :success
    assert_select "article.diary_post", :count => 20
    assert_select "li.page-item a.page-link", :text => "Older Entries", :count => 1
    assert_select "li.page-item.disabled span.page-link", :text => "Newer Entries", :count => 1

    # Try and get the second page
    get css_select("li.page-item .page-link").last["href"]
    assert_response :success
    assert_select "article.diary_post", :count => 20
    assert_select "li.page-item a.page-link", :text => "Older Entries", :count => 1
    assert_select "li.page-item a.page-link", :text => "Newer Entries", :count => 1

    # Try and get the third page
    get css_select("li.page-item .page-link").last["href"]
    assert_response :success
    assert_select "article.diary_post", :count => 10
    assert_select "li.page-item.disabled span.page-link", :text => "Older Entries", :count => 1
    assert_select "li.page-item a.page-link", :text => "Newer Entries", :count => 1

    # Go back to the second page
    get css_select("li.page-item .page-link").first["href"]
    assert_response :success
    assert_select "article.diary_post", :count => 20
    assert_select "li.page-item a.page-link", :text => "Older Entries", :count => 1
    assert_select "li.page-item a.page-link", :text => "Newer Entries", :count => 1

    # Go back to the first page
    get css_select("li.page-item .page-link").first["href"]
    assert_response :success
    assert_select "article.diary_post", :count => 20
    assert_select "li.page-item a.page-link", :text => "Older Entries", :count => 1
    assert_select "li.page-item.disabled span.page-link", :text => "Newer Entries", :count => 1
  end

  def test_index_invalid_paged
    # Try some invalid paged accesses
    %w[-1 0 fred].each do |id|
      get diary_entries_path(:before => id)
      assert_redirected_to :controller => :errors, :action => :bad_request

      get diary_entries_path(:after => id)
      assert_redirected_to :controller => :errors, :action => :bad_request
    end
  end

  def test_rss
    create(:language, :code => "de")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "de")

    get diary_rss_path
    assert_response :success, "Should be able to get a diary RSS"
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "channel>title", :count => 1
        assert_select "image", :count => 1
        assert_select "channel>item", :count => 3
      end
    end
  end

  def test_rss_language
    create(:language, :code => "de")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "de")

    get diary_rss_path(:language => "en")
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 2 # , "Diary entries should be filtered by language"
  end

  #  def test_rss_nonexisting_language
  #    get :rss, :params => { :language => 'xx', :format => :rss }
  #    assert_response :not_found, "Should not be able to get a nonexisting language diary RSS"
  #  end

  def test_rss_language_with_no_entries
    create(:language, :code => "sl")
    create(:diary_entry, :language_code => "en")

    get diary_rss_path(:language => "sl")
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 0 # , "Diary entries should be filtered by language"
  end

  def test_rss_user
    user = create(:user)
    other_user = create(:user)
    create(:diary_entry, :user => user)
    create(:diary_entry, :user => user)
    create(:diary_entry, :user => other_user)

    get diary_rss_path(:display_name => user.display_name)
    assert_response :success, "Should be able to get a specific users diary RSS"
    assert_select "rss>channel>item", :count => 2 # , "Diary entries should be filtered by user"
  end

  def test_rss_nonexisting_user
    # Try a user that has never existed
    get diary_rss_path(:display_name => "fakeUsername76543")
    assert_response :not_found, "Should not be able to get a nonexisting users diary RSS"

    # Try a suspended user
    get diary_rss_path(:display_name => create(:user, :suspended).display_name)
    assert_response :not_found, "Should not be able to get a suspended users diary RSS"

    # Try a deleted user
    get diary_rss_path(:display_name => create(:user, :deleted).display_name)
    assert_response :not_found, "Should not be able to get a deleted users diary RSS"
  end

  def test_rss_character_escaping
    create(:diary_entry, :title => "<script>")
    get diary_rss_path

    assert_match "<title>&lt;script&gt;</title>", response.body
  end

  def test_feed_delay
    create(:diary_entry, :created_at => 7.hours.ago)
    create(:diary_entry, :created_at => 5.hours.ago)
    get diary_rss_path
    assert_select "rss>channel>item", :count => 2

    with_settings(:diary_feed_delay => 6) do
      get diary_rss_path
      assert_select "rss>channel>item", :count => 1
    end
  end

  def test_show
    user = create(:user)
    suspended_user = create(:user, :suspended)
    deleted_user = create(:user, :deleted)

    # Try a normal entry that should work
    diary_entry = create(:diary_entry, :user => user)
    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_template :show

    # Try a non-integer ID
    get "/user/#{CGI.escape(user.display_name)}/diary/#{diary_entry.id})"
    assert_response :not_found
    assert_template "rescues/routing_error"

    # Try a deleted entry
    diary_entry_deleted = create(:diary_entry, :user => user, :visible => false)
    get diary_entry_path(user, diary_entry_deleted)
    assert_response :not_found

    # Try an entry by a suspended user
    diary_entry_suspended_user = create(:diary_entry, :user => suspended_user)
    get diary_entry_path(suspended_user, diary_entry_suspended_user)
    assert_response :not_found

    # Try an entry by a deleted user
    diary_entry_deleted_user = create(:diary_entry, :user => deleted_user)
    get diary_entry_path(deleted_user, diary_entry_deleted_user)
    assert_response :not_found

    # Now try as a moderator
    session_for(create(:moderator_user))
    get diary_entry_path(user, diary_entry_deleted)
    assert_response :success
    assert_template :show

    # Finally try as an administrator
    session_for(create(:administrator_user))
    get diary_entry_path(user, diary_entry_deleted)
    assert_response :success
    assert_template :show
  end

  def test_show_hidden_comments
    # Get a diary entry that has hidden comments
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    visible_comment = create(:diary_comment, :diary_entry => diary_entry)
    suspended_user_comment = create(:diary_comment, :diary_entry => diary_entry, :user => create(:user, :suspended))
    deleted_user_comment = create(:diary_comment, :diary_entry => diary_entry, :user => create(:user, :deleted))
    hidden_comment = create(:diary_comment, :diary_entry => diary_entry, :visible => false)

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_template :show
    assert_select "div.comments" do
      assert_select "p#comment#{visible_comment.id}", :count => 1
      assert_select "p#comment#{suspended_user_comment.id}", :count => 0
      assert_select "p#comment#{deleted_user_comment.id}", :count => 0
      assert_select "p#comment#{hidden_comment.id}", :count => 0
    end
  end

  def test_show_og_title
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :title => "The Important Blog Post")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:title']" do
      assert_dom "> @content", "The Important Blog Post"
    end
  end

  def test_show_og_image_with_no_image
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "nothing")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", ActionController::Base.helpers.image_url("osm_logo_256.png", :host => root_url)
    end
    assert_dom "head meta[property='og:image:alt']" do
      assert_dom "> @content", "OpenStreetMap logo"
    end
  end

  def test_show_og_image
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "![some picture](https://example.com/picture.jpg)")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", "https://example.com/picture.jpg"
    end
    assert_dom "head meta[property='og:image:alt']" do
      assert_dom "> @content", "some picture"
    end
  end

  def test_show_og_image_with_relative_uri
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "![some local picture](/picture.jpg)")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", "#{root_url}picture.jpg"
    end
    assert_dom "head meta[property='og:image:alt']" do
      assert_dom "> @content", "some local picture"
    end
  end

  def test_show_og_image_with_spaces
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "![some picture](https://example.com/the picture.jpg)")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", "https://example.com/the%20picture.jpg"
    end
    assert_dom "head meta[property='og:image:alt']" do
      assert_dom "> @content", "some picture"
    end
  end

  def test_show_og_image_with_relative_uri_and_spaces
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "![some local picture](/the picture.jpg)")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", "#{root_url}the%20picture.jpg"
    end
    assert_dom "head meta[property='og:image:alt']" do
      assert_dom "> @content", "some local picture"
    end
  end

  def test_show_og_image_with_invalid_uri
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "![](:)")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", ActionController::Base.helpers.image_url("osm_logo_256.png", :host => root_url)
    end
    assert_dom "head meta[property='og:image:alt']" do
      assert_dom "> @content", "OpenStreetMap logo"
    end
  end

  def test_show_og_image_without_alt
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "<img src='https://example.com/no_alt.gif'>")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:image']" do
      assert_dom "> @content", "https://example.com/no_alt.gif"
    end
    assert_dom "head meta[property='og:image:alt']", :count => 0
  end

  def test_show_no_og_description
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "![nope](https://example.com/nope.jpg)")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:description']" do
      assert_dom "> @content", I18n.t("layouts.intro_text")
    end
  end

  def test_show_og_description
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :body => "# Hello\n\n![hello](https://example.com/hello.jpg)\n\nFirst paragraph.\n\nSecond paragraph.")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='og:description']" do
      assert_dom "> @content", "First paragraph."
    end
  end

  def test_show_article_published_time
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user, :created_at => "2020-03-04")

    get diary_entry_path(user, diary_entry)
    assert_response :success
    assert_dom "head meta[property='article:published_time']" do
      assert_dom "> @content", "2020-03-04T00:00:00Z"
    end
  end

  def test_hide
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)

    # Try without logging in
    post hide_diary_entry_path(user, diary_entry)
    assert_response :forbidden
    assert DiaryEntry.find(diary_entry.id).visible

    # Now try as a normal user
    session_for(user)
    post hide_diary_entry_path(user, diary_entry)
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert DiaryEntry.find(diary_entry.id).visible

    # Now try as a moderator
    session_for(create(:moderator_user))
    post hide_diary_entry_path(user, diary_entry)
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert_not DiaryEntry.find(diary_entry.id).visible

    # Reset
    diary_entry.reload.update(:visible => true)

    # Finally try as an administrator
    session_for(create(:administrator_user))
    post hide_diary_entry_path(user, diary_entry)
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert_not DiaryEntry.find(diary_entry.id).visible
  end

  def test_unhide
    user = create(:user)

    # Try without logging in
    diary_entry = create(:diary_entry, :user => user, :visible => false)
    post unhide_diary_entry_path(user, diary_entry)
    assert_response :forbidden
    assert_not DiaryEntry.find(diary_entry.id).visible

    # Now try as a normal user
    session_for(user)
    post unhide_diary_entry_path(user, diary_entry)
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_not DiaryEntry.find(diary_entry.id).visible

    # Now try as a moderator
    session_for(create(:moderator_user))
    post unhide_diary_entry_path(user, diary_entry)
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert DiaryEntry.find(diary_entry.id).visible

    # Reset
    diary_entry.reload.update(:visible => true)

    # Finally try as an administrator
    session_for(create(:administrator_user))
    post unhide_diary_entry_path(user, diary_entry)
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert DiaryEntry.find(diary_entry.id).visible
  end

  def test_subscribe_page
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    path = diary_entry_subscribe_path(user, diary_entry)

    get path
    assert_redirected_to login_path(:referer => path)

    session_for(other_user)
    get path
    assert_response :success
    assert_dom ".content-body" do
      assert_dom "a[href='#{diary_entry_path(user, diary_entry)}']", :text => diary_entry.title
      assert_dom "a[href='#{user_path(user)}']", :text => user.display_name
    end
  end

  def test_subscribe_success
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)

    session_for(other_user)
    assert_difference "diary_entry.subscribers.count", 1 do
      post diary_entry_subscribe_path(user, diary_entry)
    end
    assert_response :redirect
  end

  def test_subscribe_fail
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)

    # not signed in
    assert_no_difference "diary_entry.subscribers.count" do
      post diary_entry_subscribe_path(user, diary_entry)
    end
    assert_response :forbidden

    session_for(other_user)

    # bad diary id
    post diary_entry_subscribe_path("username", 999111)
    assert_response :not_found

    # trying to subscribe when already subscribed
    post diary_entry_subscribe_path(user, diary_entry)
    assert_no_difference "diary_entry.subscribers.count" do
      post diary_entry_subscribe_path(user, diary_entry)
    end
  end

  def test_unsubscribe_page
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    path = diary_entry_unsubscribe_path(user, diary_entry)

    get path
    assert_redirected_to login_path(:referer => path)

    session_for(other_user)
    get path
    assert_response :success
    assert_dom ".content-body" do
      assert_dom "a[href='#{diary_entry_path(user, diary_entry)}']", :text => diary_entry.title
      assert_dom "a[href='#{user_path(user)}']", :text => user.display_name
    end
  end

  def test_unsubscribe_success
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)
    create(:diary_entry_subscription, :diary_entry => diary_entry, :user => other_user)

    session_for(other_user)
    assert_difference "diary_entry.subscribers.count", -1 do
      post diary_entry_unsubscribe_path(user, diary_entry)
    end
    assert_response :redirect
  end

  def test_unsubscribe_fail
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)

    # not signed in
    assert_no_difference "diary_entry.subscribers.count" do
      post diary_entry_unsubscribe_path(user, diary_entry)
    end
    assert_response :forbidden

    session_for(other_user)

    # bad diary id
    post diary_entry_unsubscribe_path("username", 999111)
    assert_response :not_found

    # trying to unsubscribe when not subscribed
    assert_no_difference "diary_entry.subscribers.count" do
      post diary_entry_unsubscribe_path(user, diary_entry)
    end
  end

  private

  def check_diary_index(*entries)
    assert_response :success
    assert_template "index"
    assert_no_missing_translations
    assert_select "article.diary_post", entries.count

    entries.each do |entry|
      assert_select "a[href=?]", "/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}"
    end
  end
end
