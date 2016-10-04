require "test_helper"

class DiaryEntryControllerTest < ActionController::TestCase
  fixtures :users, :user_roles, :languages, :friends

  include ActionView::Helpers::NumberHelper

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/diary", :method => :get },
      { :controller => "diary_entry", :action => "list" }
    )
    assert_routing(
      { :path => "/diary/language", :method => :get },
      { :controller => "diary_entry", :action => "list", :language => "language" }
    )
    assert_routing(
      { :path => "/user/username/diary", :method => :get },
      { :controller => "diary_entry", :action => "list", :display_name => "username" }
    )
    assert_routing(
      { :path => "/diary/friends", :method => :get },
      { :controller => "diary_entry", :action => "list", :friends => true }
    )
    assert_routing(
      { :path => "/diary/nearby", :method => :get },
      { :controller => "diary_entry", :action => "list", :nearby => true }
    )

    assert_routing(
      { :path => "/diary/rss", :method => :get },
      { :controller => "diary_entry", :action => "rss", :format => :rss }
    )
    assert_routing(
      { :path => "/diary/language/rss", :method => :get },
      { :controller => "diary_entry", :action => "rss", :language => "language", :format => :rss }
    )
    assert_routing(
      { :path => "/user/username/diary/rss", :method => :get },
      { :controller => "diary_entry", :action => "rss", :display_name => "username", :format => :rss }
    )

    assert_routing(
      { :path => "/user/username/diary/comments", :method => :get },
      { :controller => "diary_entry", :action => "comments", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/diary/comments/1", :method => :get },
      { :controller => "diary_entry", :action => "comments", :display_name => "username", :page => "1" }
    )

    assert_routing(
      { :path => "/diary/new", :method => :get },
      { :controller => "diary_entry", :action => "new" }
    )
    assert_routing(
      { :path => "/diary/new", :method => :post },
      { :controller => "diary_entry", :action => "new" }
    )
    assert_routing(
      { :path => "/user/username/diary/1", :method => :get },
      { :controller => "diary_entry", :action => "view", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/edit", :method => :get },
      { :controller => "diary_entry", :action => "edit", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/edit", :method => :post },
      { :controller => "diary_entry", :action => "edit", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/newcomment", :method => :post },
      { :controller => "diary_entry", :action => "comment", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/hide", :method => :post },
      { :controller => "diary_entry", :action => "hide", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/hidecomment/2", :method => :post },
      { :controller => "diary_entry", :action => "hidecomment", :display_name => "username", :id => "1", :comment => "2" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/subscribe", :method => :post },
      { :controller => "diary_entry", :action => "subscribe", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/unsubscribe", :method => :post },
      { :controller => "diary_entry", :action => "unsubscribe", :display_name => "username", :id => "1" }
    )
  end

  def test_new
    # Make sure that you are redirected to the login page when you
    # are not logged in
    get :new
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/diary/new"

    # Now try again when logged in
    get :new, {}, { :user => users(:normal_user).id }
    assert_response :success
    assert_select "title", :text => /New Diary Entry/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /New Diary Entry/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/diary/new'][method=post]", :count => 1 do
        assert_select "input#diary_entry_title[name='diary_entry[title]']", :count => 1
        assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :text => "", :count => 1
        assert_select "select#diary_entry_language_code", :count => 1
        assert_select "input#latitude[name='diary_entry[latitude]']", :count => 1
        assert_select "input#longitude[name='diary_entry[longitude]']", :count => 1
        assert_select "input[name=commit][type=submit][value=Publish]", :count => 1
        assert_select "input[name=commit][type=submit][value=Edit]", :count => 1
        assert_select "input[name=commit][type=submit][value=Preview]", :count => 1
        assert_select "input", :count => 7
      end
    end

    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    new_language_code = "en"

    # Now try creating a invalid diary entry with an empty body
    assert_no_difference "DiaryEntry.count" do
      post :new, { :commit => "save",
                   :diary_entry => { :title => new_title, :body => "", :latitude => new_latitude,
                                     :longitude => new_longitude, :language_code => new_language_code } },
           { :user => users(:normal_user).id }
    end
    assert_response :success
    assert_template :edit

    assert_nil UserPreference.where(:user_id => users(:normal_user).id, :k => "diary.default_language").first

    # Now try creating a diary entry
    assert_difference "DiaryEntry.count", 1 do
      post :new, { :commit => "save",
                   :diary_entry => { :title => new_title, :body => new_body, :latitude => new_latitude,
                                     :longitude => new_longitude, :language_code => new_language_code } },
           { :user => users(:normal_user).id }
    end
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    entry = DiaryEntry.order(:id).last
    assert_equal users(:normal_user).id, entry.user_id
    assert_equal new_title, entry.title
    assert_equal new_body, entry.body
    assert_equal new_latitude.to_f, entry.latitude
    assert_equal new_longitude.to_f, entry.longitude
    assert_equal new_language_code, entry.language_code

    # checks if user was subscribed
    assert_equal 1, entry.subscribers.length

    assert_equal new_language_code, UserPreference.where(:user_id => users(:normal_user).id, :k => "diary.default_language").first.v

    new_language_code = "de"

    # Now try creating a diary entry in a different language
    assert_difference "DiaryEntry.count", 1 do
      post :new, { :commit => "save",
                   :diary_entry => { :title => new_title, :body => new_body, :latitude => new_latitude,
                                     :longitude => new_longitude, :language_code => new_language_code } },
           { :user => users(:normal_user).id }
    end
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    entry = DiaryEntry.order(:id).last
    assert_equal users(:normal_user).id, entry.user_id
    assert_equal new_title, entry.title
    assert_equal new_body, entry.body
    assert_equal new_latitude.to_f, entry.latitude
    assert_equal new_longitude.to_f, entry.longitude
    assert_equal new_language_code, entry.language_code

    # checks if user was subscribed
    assert_equal 1, entry.subscribers.length

    assert_equal new_language_code, UserPreference.where(:user_id => users(:normal_user).id, :k => "diary.default_language").first.v
  end

  def test_new_spammy
    # Generate some spammy content
    spammy_title = "Spam Spam Spam Spam Spam"
    spammy_body = 1.upto(50).map { |n| "http://example.com/spam#{n}" }.join(" ")

    # Try creating a spammy diary entry
    assert_difference "DiaryEntry.count", 1 do
      post :new, { :commit => "save",
                   :diary_entry => { :title => spammy_title, :body => spammy_body, :language_code => "en" } },
           { :user => users(:normal_user).id }
    end
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    entry = DiaryEntry.order(:id).last
    assert_equal users(:normal_user).id, entry.user_id
    assert_equal spammy_title, entry.title
    assert_equal spammy_body, entry.body
    assert_equal "en", entry.language_code
    assert_equal "suspended", User.find(users(:normal_user).id).status

    # Follow the redirect
    get :list, { :display_name => users(:normal_user).display_name }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :suspended
  end

  def test_edit
    entry = create(:diary_entry, :user_id => users(:normal_user).id)

    # Make sure that you are redirected to the login page when you are
    # not logged in, without and with the id of the entry you want to edit
    get :edit, :display_name => entry.user.display_name, :id => entry.id
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/user/#{entry.user.display_name}/diary/#{entry.id}/edit"

    # Verify that you get a not found error, when you pass a bogus id
    get :edit, { :display_name => entry.user.display_name, :id => 9999 }, { :user => entry.user.id }
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => "No entry with the id: 9999", :count => 1
    end

    # Verify that you get redirected to view if you are not the user
    # that created the entry
    get :edit, { :display_name => entry.user.display_name, :id => entry.id }, { :user => users(:public_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => entry.user.display_name, :id => entry.id

    # Now pass the id, and check that you can edit it, when using the same
    # user as the person who created the entry
    get :edit, { :display_name => entry.user.display_name, :id => entry.id }, { :user => entry.user.id }
    assert_response :success
    assert_select "title", :text => /Edit diary entry/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /Edit diary entry/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/user/#{entry.user.display_name}/diary/#{entry.id}/edit'][method=post]", :count => 1 do
        assert_select "input#diary_entry_title[name='diary_entry[title]'][value='#{entry.title}']", :count => 1
        assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :text => entry.body, :count => 1
        assert_select "select#diary_entry_language_code", :count => 1
        assert_select "input#latitude[name='diary_entry[latitude]']", :count => 1
        assert_select "input#longitude[name='diary_entry[longitude]']", :count => 1
        assert_select "input[name=commit][type=submit][value=Save]", :count => 1
        assert_select "input[name=commit][type=submit][value=Edit]", :count => 1
        assert_select "input[name=commit][type=submit][value=Preview]", :count => 1
        assert_select "input", :count => 7
      end
    end

    # Now lets see if you can edit the diary entry
    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    new_language_code = "en"
    post :edit, { :display_name => entry.user.display_name, :id => entry.id, :commit => "save",
                  :diary_entry => { :title => new_title, :body => new_body, :latitude => new_latitude,
                                    :longitude => new_longitude, :language_code => new_language_code } },
         { :user => entry.user.id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => entry.user.display_name, :id => entry.id

    # Now check that the new data is rendered, when logged in
    get :view, { :display_name => entry.user.display_name, :id => entry.id }, { :user => entry.user.id }
    assert_response :success
    assert_template "diary_entry/view"
    assert_select "title", :text => /Users' diaries | /, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => /#{entry.user.display_name}'s diary/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "div.post_heading", :text => /#{new_title}/, :count => 1
      # This next line won't work if the text has been run through the htmlize function
      # due to formatting that could be introduced
      assert_select "p", :text => /#{new_body}/, :count => 1
      assert_select "abbr[class='geo'][title='#{number_with_precision(new_latitude, :precision => 4)}; #{number_with_precision(new_longitude, :precision => 4)}']", :count => 1
      # As we're not logged in, check that you cannot edit
      # print @response.body
      assert_select "a[href='/user/#{entry.user.display_name}/diary/#{entry.id}/edit']", :text => "Edit this entry", :count => 1
    end

    # and when not logged in as the user who wrote the entry
    get :view, { :display_name => entry.user.display_name, :id => entry.id }, { :user => entry.user.id }
    assert_response :success
    assert_template "diary_entry/view"
    assert_select "title", :text => /Users' diaries | /, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => /#{users(:normal_user).display_name}'s diary/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "div.post_heading", :text => /#{new_title}/, :count => 1
      # This next line won't work if the text has been run through the htmlize function
      # due to formatting that could be introduced
      assert_select "p", :text => /#{new_body}/, :count => 1
      assert_select "abbr[class=geo][title='#{number_with_precision(new_latitude, :precision => 4)}; #{number_with_precision(new_longitude, :precision => 4)}']", :count => 1
      # As we're not logged in, check that you cannot edit
      assert_select "li[class='hidden show_if_user_#{entry.user.id}']", :count => 1 do
        assert_select "a[href='/user/#{entry.user.display_name}/diary/#{entry.id}/edit']", :text => "Edit this entry", :count => 1
      end
    end
  end

  def test_edit_i18n
    diary_entry = create(:diary_entry, :language_code => "en")
    get :edit, { :display_name => users(:normal_user).display_name, :id => diary_entry.id }, { :user => users(:normal_user).id }
    assert_response :success
    assert_select "span[class=translation_missing]", false, "Missing translation in edit diary entry"
  end

  def test_comment
    entry = create(:diary_entry, :user_id => users(:normal_user).id)

    # Make sure that you are denied when you are not logged in
    post :comment, :display_name => entry.user.display_name, :id => entry.id
    assert_response :forbidden

    # Verify that you get a not found error, when you pass a bogus id
    post :comment, { :display_name => entry.user.display_name, :id => 9999 }, { :user => users(:public_user).id }
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => "No entry with the id: 9999", :count => 1
    end

    # Now try an invalid comment with an empty body
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_difference "DiaryComment.count" do
        assert_no_difference "entry.subscribers.count" do
          post :comment, { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => "" } }, { :user => users(:public_user).id }
        end
      end
    end
    assert_response :success
    assert_template :view

    # Now try again with the right id
    assert_difference "ActionMailer::Base.deliveries.size", entry.subscribers.count do
      assert_difference "DiaryComment.count", 1 do
        assert_difference "entry.subscribers.count", 1 do
          post :comment, { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => "New comment" } }, { :user => users(:public_user).id }
        end
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => entry.user.display_name, :id => entry.id
    email = ActionMailer::Base.deliveries.first
    assert_equal [users(:normal_user).email], email.to
    assert_equal "[OpenStreetMap] #{users(:public_user).display_name} commented on your diary entry", email.subject
    assert_match /New comment/, email.text_part.decoded
    assert_match /New comment/, email.html_part.decoded
    ActionMailer::Base.deliveries.clear
    comment = DiaryComment.order(:id).last
    assert_equal entry.id, comment.diary_entry_id
    assert_equal users(:public_user).id, comment.user_id
    assert_equal "New comment", comment.body

    # Now view the diary entry, and check the new comment is present
    get :view, :display_name => entry.user.display_name, :id => entry.id
    assert_response :success
    assert_select ".diary-comment", :count => 1 do
      assert_select "#comment#{comment.id}", :count => 1 do
        assert_select "a[href='/user/#{users(:public_user).display_name}']", :text => users(:public_user).display_name, :count => 1
      end
      assert_select ".richtext", :text => /New comment/, :count => 1
    end
  end

  def test_comment_spammy
    # Find the entry to comment on
    entry = create(:diary_entry, :user_id => users(:normal_user).id)

    # Generate some spammy content
    spammy_text = 1.upto(50).map { |n| "http://example.com/spam#{n}" }.join(" ")

    # Try creating a spammy comment
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "DiaryComment.count", 1 do
        post :comment, { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => spammy_text } }, { :user => users(:public_user).id }
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => entry.user.display_name, :id => entry.id
    email = ActionMailer::Base.deliveries.first
    assert_equal [users(:normal_user).email], email.to
    assert_equal "[OpenStreetMap] #{users(:public_user).display_name} commented on your diary entry", email.subject
    assert_match %r{http://example.com/spam}, email.text_part.decoded
    assert_match %r{http://example.com/spam}, email.html_part.decoded
    ActionMailer::Base.deliveries.clear
    comment = DiaryComment.order(:id).last
    assert_equal entry.id, comment.diary_entry_id
    assert_equal users(:public_user).id, comment.user_id
    assert_equal spammy_text, comment.body
    assert_equal "suspended", User.find(users(:public_user).id).status

    # Follow the redirect
    get :list, { :display_name => users(:normal_user).display_name }, { :user => users(:public_user).id }
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :suspended

    # Now view the diary entry, and check the new comment is not present
    get :view, :display_name => entry.user.display_name, :id => entry.id
    assert_response :success
    assert_select ".diary-comment", :count => 0
  end

  def test_list_all
    diary_entry = create(:diary_entry)
    geo_entry = create(:diary_entry, :latitude => 51.50763, :longitude => -0.10781)
    public_entry = create(:diary_entry, :user_id => users(:public_user).id)

    # Try a list of all diary entries
    get :list
    check_diary_list diary_entry, geo_entry, public_entry
  end

  def test_list_user
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)
    geo_entry = create(:diary_entry, :user_id => users(:normal_user).id, :latitude => 51.50763, :longitude => -0.10781)
    _other_entry = create(:diary_entry, :user_id => users(:public_user).id)

    # Try a list of diary entries for a valid user
    get :list, :display_name => users(:normal_user).display_name
    check_diary_list diary_entry, geo_entry

    # Try a list of diary entries for an invalid user
    get :list, :display_name => "No Such User"
    assert_response :not_found
    assert_template "user/no_such_user"
  end

  def test_list_friends
    diary_entry = create(:diary_entry, :user_id => friends(:normal_user_with_second_user).friend_user_id)
    _other_entry = create(:diary_entry, :user_id => users(:second_public_user).id)

    # Try a list of diary entries for your friends when not logged in
    get :list, :friends => true
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/diary/friends"

    # Try a list of diary entries for your friends when logged in
    get :list, { :friends => true }, { :user => users(:normal_user).id }
    check_diary_list diary_entry
    get :list, { :friends => true }, { :user => users(:public_user).id }
    check_diary_list
  end

  def test_list_nearby
    diary_entry = create(:diary_entry, :user_id => users(:public_user).id)

    # Try a list of diary entries for nearby users when not logged in
    get :list, :nearby => true
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => :login, :referer => "/diary/nearby"

    # Try a list of diary entries for nearby users when logged in
    get :list, { :nearby => true }, { :user => users(:german_user).id }
    check_diary_list diary_entry
    get :list, { :nearby => true }, { :user => users(:public_user).id }
    check_diary_list
  end

  def test_list_language
    diary_entry_en = create(:diary_entry, :language_code => "en")
    diary_entry_en2 = create(:diary_entry, :language_code => "en")
    diary_entry_de = create(:diary_entry, :language_code => "de")

    # Try a list of diary entries in english
    get :list, :language => "en"
    check_diary_list diary_entry_en, diary_entry_en2

    # Try a list of diary entries in german
    get :list, :language => "de"
    check_diary_list diary_entry_de

    # Try a list of diary entries in slovenian
    get :list, :language => "sl"
    check_diary_list
  end

  def test_rss
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "de")

    get :rss, :format => :rss
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
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "de")

    get :rss, :language => "en", :format => :rss
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 2 # , "Diary entries should be filtered by language"
  end

  #  def test_rss_nonexisting_language
  #    get :rss, {:language => 'xx', :format => :rss}
  #    assert_response :not_found, "Should not be able to get a nonexisting language diary RSS"
  #  end

  def test_rss_language_with_no_entries
    create(:diary_entry, :language_code => "en")

    get :rss, :language => "sl", :format => :rss
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 0 # , "Diary entries should be filtered by language"
  end

  def test_rss_user
    create(:diary_entry, :user_id => users(:normal_user).id)
    create(:diary_entry, :user_id => users(:normal_user).id)
    create(:diary_entry, :user_id => users(:public_user).id)

    get :rss, :display_name => users(:normal_user).display_name, :format => :rss
    assert_response :success, "Should be able to get a specific users diary RSS"
    assert_select "rss>channel>item", :count => 2 # , "Diary entries should be filtered by user"
  end

  def test_rss_nonexisting_user
    # Try a user that has never existed
    get :rss, :display_name => "fakeUsername76543", :format => :rss
    assert_response :not_found, "Should not be able to get a nonexisting users diary RSS"

    # Try a suspended user
    get :rss, :display_name => users(:suspended_user).display_name, :format => :rss
    assert_response :not_found, "Should not be able to get a suspended users diary RSS"

    # Try a deleted user
    get :rss, :display_name => users(:deleted_user).display_name, :format => :rss
    assert_response :not_found, "Should not be able to get a deleted users diary RSS"
  end

  def test_view
    # Try a normal entry that should work
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)
    get :view, :display_name => users(:normal_user).display_name, :id => diary_entry.id
    assert_response :success
    assert_template :view

    # Try a deleted entry
    diary_entry_deleted = create(:diary_entry, :user_id => users(:normal_user).id, :visible => false)
    get :view, :display_name => users(:normal_user).display_name, :id => diary_entry_deleted.id
    assert_response :not_found

    # Try an entry by a suspended user
    diary_entry_suspended = create(:diary_entry, :user_id => users(:suspended_user).id)
    get :view, :display_name => users(:suspended_user).display_name, :id => diary_entry_suspended.id
    assert_response :not_found

    # Try an entry by a deleted user
    diary_entry_deleted = create(:diary_entry, :user_id => users(:deleted_user).id)
    get :view, :display_name => users(:deleted_user).display_name, :id => diary_entry_deleted.id
    assert_response :not_found
  end

  def test_view_hidden_comments
    # Get a diary entry that has hidden comments
    diary_entry = create(:diary_entry)
    visible_comment = create(:diary_comment, :diary_entry => diary_entry)
    suspended_user_comment = create(:diary_comment, :diary_entry => diary_entry, :user_id => users(:suspended_user).id)
    deleted_user_comment = create(:diary_comment, :diary_entry => diary_entry, :user_id => users(:deleted_user).id)
    hidden_comment = create(:diary_comment, :diary_entry => diary_entry, :visible => false)

    get :view, :display_name => users(:normal_user).display_name, :id => diary_entry.id
    assert_response :success
    assert_template :view
    assert_select "div.comments" do
      assert_select "p#comment#{visible_comment.id}", :count => 1
      assert_select "p#comment#{suspended_user_comment.id}", :count => 0
      assert_select "p#comment#{deleted_user_comment.id}", :count => 0
      assert_select "p#comment#{hidden_comment.id}", :count => 0
    end
  end

  def test_hide
    # Try without logging in
    diary_entry = create(:diary_entry)
    post :hide, :display_name => users(:normal_user).display_name, :id => diary_entry.id
    assert_response :forbidden
    assert_equal true, DiaryEntry.find(diary_entry.id).visible

    # Now try as a normal user
    post :hide, { :display_name => users(:normal_user).display_name, :id => diary_entry.id }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name, :id => diary_entry.id
    assert_equal true, DiaryEntry.find(diary_entry.id).visible

    # Finally try as an administrator
    post :hide, { :display_name => users(:normal_user).display_name, :id => diary_entry.id }, { :user => users(:administrator_user).id }
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    assert_equal false, DiaryEntry.find(diary_entry.id).visible
  end

  def test_hidecomment
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)
    # Try without logging in
    post :hidecomment, :display_name => users(:normal_user).display_name, :id => diary_entry.id, :comment => diary_comment.id
    assert_response :forbidden
    assert_equal true, DiaryComment.find(diary_comment.id).visible

    # Now try as a normal user
    post :hidecomment, { :display_name => users(:normal_user).display_name, :id => diary_entry.id, :comment => diary_comment.id }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name, :id => diary_entry.id
    assert_equal true, DiaryComment.find(diary_comment.id).visible

    # Finally try as an administrator
    post :hidecomment, { :display_name => users(:normal_user).display_name, :id => diary_entry.id, :comment => diary_comment.id }, { :user => users(:administrator_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name, :id => diary_entry.id
    assert_equal false, DiaryComment.find(diary_comment.id).visible
  end

  def test_comments
    # Test a user with no comments
    get :comments, :display_name => users(:normal_user).display_name
    assert_response :success
    assert_template :comments
    assert_select "table.messages" do
      assert_select "tr", :count => 1 # header, no comments
    end

    # Test a user with a comment
    create(:diary_comment, :user_id => users(:public_user).id)

    get :comments, :display_name => users(:public_user).display_name
    assert_response :success
    assert_template :comments
    assert_select "table.messages" do
      assert_select "tr", :count => 2 # header and one comment
    end

    # Test a suspended user
    get :comments, :display_name => users(:suspended_user).display_name
    assert_response :not_found

    # Test a deleted user
    get :comments, :display_name => users(:deleted_user).display_name
    assert_response :not_found
  end

  ##
  # test subscribe success
  def test_subscribe_success
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)

    #basic_authorization(users(:public_user).email, "test")

    assert_difference "diary_entry.subscribers.count", 1 do
      post :subscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:public_user).id}
    end
    assert_response :redirect
  end

  ##
  # test subscribe fail
  def test_subscribe_fail
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)

    # not signed in
    assert_no_difference "diary_entry.subscribers.count", 1 do
      post :subscribe, :id => diary_entry.id, :display_name => diary_entry.user.display_name
    end
    assert_response :forbidden

    # bad diary id
    post :subscribe, {:id => 999111, :display_name => "username"}, { :user => users(:public_user).id}
    assert_response :not_found

    # trying to subscribe when already subscribed
    post :subscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:public_user).id}
    assert_no_difference "diary_entry.subscribers.count" do
      post :subscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:public_user).id}
    end
  end

  ##
  # test unsubscribe success
  def test_unsubscribe_success
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)

    assert_difference "diary_entry.subscribers.count", -1 do
      post :unsubscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:normal_user).id}
    end
    assert_response :redirect

    post :subscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:public_user).id}
    assert_difference "diary_entry.subscribers.count", -1 do
      post :unsubscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:public_user).id}
    end
    assert_response :redirect
  end

  ##
  # test unsubscribe fail
  def test_unsubscribe_fail
    diary_entry = create(:diary_entry, :user_id => users(:normal_user).id)

    # not signed in
    assert_no_difference "diary_entry.subscribers.count" do
      post :unsubscribe, :id => diary_entry.id, :display_name => diary_entry.user.display_name
    end
    assert_response :forbidden

    # bad diary id
    post :unsubscribe, {:id => 999111, :display_name => "username"}, { :user => users(:public_user).id}
    assert_response :not_found

    # trying to subscribe when already subscribed
    assert_no_difference "diary_entry.subscribers.count" do
      post :unsubscribe, {:id => diary_entry.id, :display_name => diary_entry.user.display_name}, { :user => users(:public_user).id}
    end
  end

  private

  def check_diary_list(*entries)
    assert_response :success
    assert_template "list"
    assert_no_missing_translations
    assert_select "div.diary_post", entries.count

    entries.each do |entry|
      assert_select "a[href=?]", "/user/#{entry.user.display_name}/diary/#{entry.id}"
    end
  end
end
