require "test_helper"

class DiaryEntriesControllerTest < ActionController::TestCase
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
      { :path => "/user/username/diary/comments", :method => :get },
      { :controller => "diary_entries", :action => "comments", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/diary/comments/1", :method => :get },
      { :controller => "diary_entries", :action => "comments", :display_name => "username", :page => "1" }
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
      { :path => "/user/username/diary/1/newcomment", :method => :post },
      { :controller => "diary_entries", :action => "comment", :display_name => "username", :id => "1" }
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
      { :path => "/user/username/diary/1/hidecomment/2", :method => :post },
      { :controller => "diary_entries", :action => "hidecomment", :display_name => "username", :id => "1", :comment => "2" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/unhidecomment/2", :method => :post },
      { :controller => "diary_entries", :action => "unhidecomment", :display_name => "username", :id => "1", :comment => "2" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/subscribe", :method => :post },
      { :controller => "diary_entries", :action => "subscribe", :display_name => "username", :id => "1" }
    )
    assert_routing(
      { :path => "/user/username/diary/1/unsubscribe", :method => :post },
      { :controller => "diary_entries", :action => "unsubscribe", :display_name => "username", :id => "1" }
    )
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    get :new
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/diary/new"
  end

  def test_new_form
    # Now try again when logged in
    get :new, :session => { :user => create(:user) }
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
        assert_select "input[name=commit][type=submit][value=Edit]", :count => 1
        assert_select "input[name=commit][type=submit][value=Preview]", :count => 1
        assert_select "input", :count => 7
      end
    end
  end

  def test_new_get_with_params
    # Now try creating a diary entry using get
    assert_difference "DiaryEntry.count", 0 do
      get :new,
          :params => { :commit => "save",
                       :diary_entry => { :title => "New Title", :body => "This is a new body for the diary entry", :latitude => "1.1",
                                         :longitude => "2.2", :language_code => "en" } },
          :session => { :user => create(:user).id }
    end
    assert_response :success
    assert_template :new
  end

  def test_create_no_body
    # Now try creating a invalid diary entry with an empty body
    user = create(:user)
    assert_no_difference "DiaryEntry.count" do
      post :create,
           :params => { :commit => "save",
                        :diary_entry => { :title => "New Title", :body => "", :latitude => "1.1",
                                          :longitude => "2.2", :language_code => "en" } },
           :session => { :user => user.id }
    end
    assert_response :success
    assert_template :new

    assert_nil UserPreference.where(:user_id => user.id, :k => "diary.default_language").first
  end

  def test_create
    # Now try creating a diary entry
    user = create(:user)
    assert_difference "DiaryEntry.count", 1 do
      post :create,
           :params => { :commit => "save",
                        :diary_entry => { :title => "New Title", :body => "This is a new body for the diary entry", :latitude => "1.1",
                                          :longitude => "2.2", :language_code => "en" } },
           :session => { :user => user.id }
    end
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    entry = DiaryEntry.order(:id).last
    assert_equal user.id, entry.user_id
    assert_equal "New Title", entry.title
    assert_equal "This is a new body for the diary entry", entry.body
    assert_equal "1.1".to_f, entry.latitude
    assert_equal "2.2".to_f, entry.longitude
    assert_equal "en", entry.language_code

    # checks if user was subscribed
    assert_equal 1, entry.subscribers.length

    assert_equal "en", UserPreference.where(:user_id => user.id, :k => "diary.default_language").first.v
  end

  def test_create_german
    create(:language, :code => "de")
    user = create(:user)

    # Now try creating a diary entry in a different language
    assert_difference "DiaryEntry.count", 1 do
      post :create,
           :params => { :commit => "save",
                        :diary_entry => { :title => "New Title", :body => "This is a new body for the diary entry", :latitude => "1.1",
                                          :longitude => "2.2", :language_code => "de" } },
           :session => { :user => user.id }
    end
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    entry = DiaryEntry.order(:id).last
    assert_equal user.id, entry.user_id
    assert_equal "New Title", entry.title
    assert_equal "This is a new body for the diary entry", entry.body
    assert_equal "1.1".to_f, entry.latitude
    assert_equal "2.2".to_f, entry.longitude
    assert_equal "de", entry.language_code

    # checks if user was subscribed
    assert_equal 1, entry.subscribers.length

    assert_equal "de", UserPreference.where(:user_id => user.id, :k => "diary.default_language").first.v
  end

  def test_new_spammy
    user = create(:user)
    # Generate some spammy content
    spammy_title = "Spam Spam Spam Spam Spam"
    spammy_body = 1.upto(50).map { |n| "http://example.com/spam#{n}" }.join(" ")

    # Try creating a spammy diary entry
    assert_difference "DiaryEntry.count", 1 do
      post :create,
           :params => { :commit => "save",
                        :diary_entry => { :title => spammy_title, :body => spammy_body, :language_code => "en" } },
           :session => { :user => user.id }
    end
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    entry = DiaryEntry.order(:id).last
    assert_equal user.id, entry.user_id
    assert_equal spammy_title, entry.title
    assert_equal spammy_body, entry.body
    assert_equal "en", entry.language_code
    assert_equal "suspended", User.find(user.id).status

    # Follow the redirect
    get :index,
        :params => { :display_name => user.display_name },
        :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :suspended
  end

  def test_edit
    user = create(:user)
    other_user = create(:user)

    entry = create(:diary_entry, :user => user)

    # Make sure that you are redirected to the login page when you are
    # not logged in, without and with the id of the entry you want to edit
    get :edit,
        :params => { :display_name => entry.user.display_name, :id => entry.id }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}/edit"

    # Verify that you get a not found error, when you pass a bogus id
    get :edit,
        :params => { :display_name => entry.user.display_name, :id => 9999 },
        :session => { :user => entry.user }
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => "No entry with the id: 9999", :count => 1
    end

    # Verify that you get redirected to show if you are not the user
    # that created the entry
    get :edit,
        :params => { :display_name => entry.user.display_name, :id => entry.id },
        :session => { :user => other_user }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => entry.user.display_name, :id => entry.id

    # Now pass the id, and check that you can edit it, when using the same
    # user as the person who created the entry
    get :edit,
        :params => { :display_name => entry.user.display_name, :id => entry.id },
        :session => { :user => entry.user }
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
        assert_select "input[name=commit][type=submit][value=Edit]", :count => 1
        assert_select "input[name=commit][type=submit][value=Preview]", :count => 1
        assert_select "input", :count => 8
      end
    end

    # Now lets see if you can edit the diary entry
    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    new_language_code = "en"
    put :update,
        :params => { :display_name => entry.user.display_name, :id => entry.id, :commit => "save",
                     :diary_entry => { :title => new_title, :body => new_body, :latitude => new_latitude,
                                       :longitude => new_longitude, :language_code => new_language_code } },
        :session => { :user => entry.user.id }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => entry.user.display_name, :id => entry.id

    # Now check that the new data is rendered, when logged in
    get :show,
        :params => { :display_name => entry.user.display_name, :id => entry.id },
        :session => { :user => entry.user }
    assert_response :success
    assert_template "show"
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
      assert_select "a[href='/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}/edit']", :text => "Edit this entry", :count => 1
    end

    # and when not logged in as the user who wrote the entry
    get :show,
        :params => { :display_name => entry.user.display_name, :id => entry.id },
        :session => { :user => create(:user) }
    assert_response :success
    assert_template "show"
    assert_select "title", :text => /Users' diaries | /, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => /#{entry.user.display_name}'s diary/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "div.post_heading", :text => /#{new_title}/, :count => 1
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
    get :edit,
        :params => { :display_name => user.display_name, :id => diary_entry.id },
        :session => { :user => user }
    assert_response :success
    assert_select "span[class=translation_missing]", false, "Missing translation in edit diary entry"
  end

  def test_comment
    user = create(:user)
    other_user = create(:user)
    entry = create(:diary_entry, :user => user)

    # Make sure that you are denied when you are not logged in
    post :comment,
         :params => { :display_name => entry.user.display_name, :id => entry.id }
    assert_response :forbidden

    # Verify that you get a not found error, when you pass a bogus id
    post :comment,
         :params => { :display_name => entry.user.display_name, :id => 9999 },
         :session => { :user => other_user }
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => "No entry with the id: 9999", :count => 1
    end

    post :subscribe,
         :params => { :id => entry.id, :display_name => entry.user.display_name },
         :session => { :user => user }

    # Now try an invalid comment with an empty body
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_difference "DiaryComment.count" do
        assert_no_difference "entry.subscribers.count" do
          perform_enqueued_jobs do
            post :comment,
                 :params => { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => "" } },
                 :session => { :user => other_user }
          end
        end
      end
    end
    assert_response :success
    assert_template :show

    # Now try again with the right id
    assert_difference "ActionMailer::Base.deliveries.size", entry.subscribers.count do
      assert_difference "DiaryComment.count", 1 do
        assert_difference "entry.subscribers.count", 1 do
          perform_enqueued_jobs do
            post :comment,
                 :params => { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => "New comment" } },
                 :session => { :user => other_user }
          end
        end
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => entry.user.display_name, :id => entry.id
    email = ActionMailer::Base.deliveries.first
    assert_equal [user.email], email.to
    assert_equal "[OpenStreetMap] #{other_user.display_name} commented on a diary entry", email.subject
    assert_match(/New comment/, email.text_part.decoded)
    assert_match(/New comment/, email.html_part.decoded)
    ActionMailer::Base.deliveries.clear
    comment = DiaryComment.order(:id).last
    assert_equal entry.id, comment.diary_entry_id
    assert_equal other_user.id, comment.user_id
    assert_equal "New comment", comment.body

    # Now show the diary entry, and check the new comment is present
    get :show,
        :params => { :display_name => entry.user.display_name, :id => entry.id }
    assert_response :success
    assert_select ".diary-comment", :count => 1 do
      assert_select "#comment#{comment.id}", :count => 1 do
        assert_select "a[href='/user/#{ERB::Util.u(other_user.display_name)}']", :text => other_user.display_name, :count => 1
      end
      assert_select ".richtext", :text => /New comment/, :count => 1
    end
  end

  def test_comment_spammy
    user = create(:user)
    other_user = create(:user)

    # Find the entry to comment on
    entry = create(:diary_entry, :user => user)
    post :subscribe,
         :params => { :id => entry.id, :display_name => entry.user.display_name },
         :session => { :user => user }

    # Generate some spammy content
    spammy_text = 1.upto(50).map { |n| "http://example.com/spam#{n}" }.join(" ")

    # Try creating a spammy comment
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "DiaryComment.count", 1 do
        perform_enqueued_jobs do
          post :comment,
               :params => { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => spammy_text } },
               :session => { :user => other_user }
        end
      end
    end
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => entry.user.display_name, :id => entry.id
    email = ActionMailer::Base.deliveries.first
    assert_equal [user.email], email.to
    assert_equal "[OpenStreetMap] #{other_user.display_name} commented on a diary entry", email.subject
    assert_match %r{http://example.com/spam}, email.text_part.decoded
    assert_match %r{http://example.com/spam}, email.html_part.decoded
    ActionMailer::Base.deliveries.clear
    comment = DiaryComment.order(:id).last
    assert_equal entry.id, comment.diary_entry_id
    assert_equal other_user.id, comment.user_id
    assert_equal spammy_text, comment.body
    assert_equal "suspended", User.find(other_user.id).status

    # Follow the redirect
    get :index,
        :params => { :display_name => user.display_name },
        :session => { :user => other_user }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :suspended

    # Now show the diary entry, and check the new comment is not present
    get :show,
        :params => { :display_name => entry.user.display_name, :id => entry.id }
    assert_response :success
    assert_select ".diary-comment", :count => 0
  end

  def test_index_all
    diary_entry = create(:diary_entry)
    geo_entry = create(:diary_entry, :latitude => 51.50763, :longitude => -0.10781)
    public_entry = create(:diary_entry, :user => create(:user))

    # Try a list of all diary entries
    get :index
    check_diary_index diary_entry, geo_entry, public_entry
  end

  def test_index_user
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)
    geo_entry = create(:diary_entry, :user => user, :latitude => 51.50763, :longitude => -0.10781)
    _other_entry = create(:diary_entry, :user => other_user)

    # Try a list of diary entries for a valid user
    get :index, :params => { :display_name => user.display_name }
    check_diary_index diary_entry, geo_entry

    # Try a list of diary entries for an invalid user
    get :index, :params => { :display_name => "No Such User" }
    assert_response :not_found
    assert_template "users/no_such_user"
  end

  def test_index_friends
    user = create(:user)
    other_user = create(:user)
    friendship = create(:friendship, :befriender => user)
    diary_entry = create(:diary_entry, :user => friendship.befriendee)
    _other_entry = create(:diary_entry, :user => other_user)

    # Try a list of diary entries for your friends when not logged in
    get :index, :params => { :friends => true }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/diary/friends"

    # Try a list of diary entries for your friends when logged in
    get :index, :params => { :friends => true }, :session => { :user => user }
    check_diary_index diary_entry
    get :index, :params => { :friends => true }, :session => { :user => other_user }
    check_diary_index
  end

  def test_index_nearby
    user = create(:user, :home_lat => 12, :home_lon => 12)
    nearby_user = create(:user, :home_lat => 11.9, :home_lon => 12.1)

    diary_entry = create(:diary_entry, :user => user)

    # Try a list of diary entries for nearby users when not logged in
    get :index, :params => { :nearby => true }
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/diary/nearby"

    # Try a list of diary entries for nearby users when logged in
    get :index, :params => { :nearby => true }, :session => { :user => nearby_user }
    check_diary_index diary_entry
    get :index, :params => { :nearby => true }, :session => { :user => user }
    check_diary_index
  end

  def test_index_language
    create(:language, :code => "de")
    create(:language, :code => "sl")
    diary_entry_en = create(:diary_entry, :language_code => "en")
    diary_entry_en2 = create(:diary_entry, :language_code => "en")
    diary_entry_de = create(:diary_entry, :language_code => "de")

    # Try a list of diary entries in english
    get :index, :params => { :language => "en" }
    check_diary_index diary_entry_en, diary_entry_en2

    # Try a list of diary entries in german
    get :index, :params => { :language => "de" }
    check_diary_index diary_entry_de

    # Try a list of diary entries in slovenian
    get :index, :params => { :language => "sl" }
    check_diary_index
  end

  def test_index_paged
    # Create several pages worth of diary entries
    create_list(:diary_entry, 50)

    # Try and get the index
    get :index
    assert_response :success
    assert_select "div.diary_post", :count => 20

    # Try and get the second page
    get :index, :params => { :page => 2 }
    assert_response :success
    assert_select "div.diary_post", :count => 20
  end

  def test_rss
    create(:language, :code => "de")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "en")
    create(:diary_entry, :language_code => "de")

    get :rss, :params => { :format => :rss }
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

    get :rss, :params => { :language => "en", :format => :rss }
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

    get :rss, :params => { :language => "sl", :format => :rss }
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 0 # , "Diary entries should be filtered by language"
  end

  def test_rss_user
    user = create(:user)
    other_user = create(:user)
    create(:diary_entry, :user => user)
    create(:diary_entry, :user => user)
    create(:diary_entry, :user => other_user)

    get :rss, :params => { :display_name => user.display_name, :format => :rss }
    assert_response :success, "Should be able to get a specific users diary RSS"
    assert_select "rss>channel>item", :count => 2 # , "Diary entries should be filtered by user"
  end

  def test_rss_nonexisting_user
    # Try a user that has never existed
    get :rss, :params => { :display_name => "fakeUsername76543", :format => :rss }
    assert_response :not_found, "Should not be able to get a nonexisting users diary RSS"

    # Try a suspended user
    get :rss, :params => { :display_name => create(:user, :suspended).display_name, :format => :rss }
    assert_response :not_found, "Should not be able to get a suspended users diary RSS"

    # Try a deleted user
    get :rss, :params => { :display_name => create(:user, :deleted).display_name, :format => :rss }
    assert_response :not_found, "Should not be able to get a deleted users diary RSS"
  end

  def test_rss_character_escaping
    create(:diary_entry, :title => "<script>")
    get :rss, :params => { :format => :rss }

    assert_match "<title>&lt;script&gt;</title>", response.body
  end

  def test_feed_delay
    create(:diary_entry, :created_at => 7.hours.ago)
    create(:diary_entry, :created_at => 5.hours.ago)
    get :rss, :params => { :format => :rss }
    assert_select "rss>channel>item", :count => 2

    with_diary_feed_delay(6) do
      get :rss, :params => { :format => :rss }
      assert_select "rss>channel>item", :count => 1
    end
  end

  def test_show
    user = create(:user)
    suspended_user = create(:user, :suspended)
    deleted_user = create(:user, :deleted)

    # Try a normal entry that should work
    diary_entry = create(:diary_entry, :user => user)
    get :show, :params => { :display_name => user.display_name, :id => diary_entry.id }
    assert_response :success
    assert_template :show

    # Try a deleted entry
    diary_entry_deleted = create(:diary_entry, :user => user, :visible => false)
    get :show, :params => { :display_name => user.display_name, :id => diary_entry_deleted.id }
    assert_response :not_found

    # Try an entry by a suspended user
    diary_entry_suspended = create(:diary_entry, :user => suspended_user)
    get :show, :params => { :display_name => suspended_user.display_name, :id => diary_entry_suspended.id }
    assert_response :not_found

    # Try an entry by a deleted user
    diary_entry_deleted = create(:diary_entry, :user => deleted_user)
    get :show, :params => { :display_name => deleted_user.display_name, :id => diary_entry_deleted.id }
    assert_response :not_found
  end

  def test_show_hidden_comments
    # Get a diary entry that has hidden comments
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    visible_comment = create(:diary_comment, :diary_entry => diary_entry)
    suspended_user_comment = create(:diary_comment, :diary_entry => diary_entry, :user => create(:user, :suspended))
    deleted_user_comment = create(:diary_comment, :diary_entry => diary_entry, :user => create(:user, :deleted))
    hidden_comment = create(:diary_comment, :diary_entry => diary_entry, :visible => false)

    get :show, :params => { :display_name => user.display_name, :id => diary_entry.id }
    assert_response :success
    assert_template :show
    assert_select "div.comments" do
      assert_select "p#comment#{visible_comment.id}", :count => 1
      assert_select "p#comment#{suspended_user_comment.id}", :count => 0
      assert_select "p#comment#{deleted_user_comment.id}", :count => 0
      assert_select "p#comment#{hidden_comment.id}", :count => 0
    end
  end

  def test_hide
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)

    # Try without logging in
    post :hide,
         :params => { :display_name => user.display_name, :id => diary_entry.id }
    assert_response :forbidden
    assert_equal true, DiaryEntry.find(diary_entry.id).visible

    # Now try as a normal user
    post :hide,
         :params => { :display_name => user.display_name, :id => diary_entry.id },
         :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal true, DiaryEntry.find(diary_entry.id).visible

    # Now try as a moderator
    post :hide,
         :params => { :display_name => user.display_name, :id => diary_entry.id },
         :session => { :user => create(:moderator_user) }
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert_equal false, DiaryEntry.find(diary_entry.id).visible

    # Reset
    diary_entry.reload.update(:visible => true)

    # Finally try as an administrator
    post :hide,
         :params => { :display_name => user.display_name, :id => diary_entry.id },
         :session => { :user => create(:administrator_user) }
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert_equal false, DiaryEntry.find(diary_entry.id).visible
  end

  def test_unhide
    user = create(:user)

    # Try without logging in
    diary_entry = create(:diary_entry, :user => user, :visible => false)
    post :unhide,
         :params => { :display_name => user.display_name, :id => diary_entry.id }
    assert_response :forbidden
    assert_equal false, DiaryEntry.find(diary_entry.id).visible

    # Now try as a normal user
    post :unhide,
         :params => { :display_name => user.display_name, :id => diary_entry.id },
         :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal false, DiaryEntry.find(diary_entry.id).visible

    # Finally try as an administrator
    post :unhide,
         :params => { :display_name => user.display_name, :id => diary_entry.id },
         :session => { :user => create(:administrator_user) }
    assert_response :redirect
    assert_redirected_to :action => :index, :display_name => user.display_name
    assert_equal true, DiaryEntry.find(diary_entry.id).visible
  end

  def test_hidecomment
    user = create(:user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry)

    # Try without logging in
    post :hidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id }
    assert_response :forbidden
    assert_equal true, DiaryComment.find(diary_comment.id).visible

    # Now try as a normal user
    post :hidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id },
         :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal true, DiaryComment.find(diary_comment.id).visible

    # Try as a moderator
    post :hidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id },
         :session => { :user => create(:moderator_user) }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name, :id => diary_entry.id
    assert_equal false, DiaryComment.find(diary_comment.id).visible

    # Reset
    diary_comment.reload.update(:visible => true)

    # Finally try as an administrator
    post :hidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id },
         :session => { :user => create(:administrator_user) }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name, :id => diary_entry.id
    assert_equal false, DiaryComment.find(diary_comment.id).visible
  end

  def test_unhidecomment
    user = create(:user)
    administrator_user = create(:administrator_user)
    diary_entry = create(:diary_entry, :user => user)
    diary_comment = create(:diary_comment, :diary_entry => diary_entry, :visible => false)
    # Try without logging in
    post :unhidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id }
    assert_response :forbidden
    assert_equal false, DiaryComment.find(diary_comment.id).visible

    # Now try as a normal user
    post :unhidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id },
         :session => { :user => user }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal false, DiaryComment.find(diary_comment.id).visible

    # Finally try as an administrator
    post :unhidecomment,
         :params => { :display_name => user.display_name, :id => diary_entry.id, :comment => diary_comment.id },
         :session => { :user => administrator_user }
    assert_response :redirect
    assert_redirected_to :action => :show, :display_name => user.display_name, :id => diary_entry.id
    assert_equal true, DiaryComment.find(diary_comment.id).visible
  end

  def test_comments
    user = create(:user)
    other_user = create(:user)
    suspended_user = create(:user, :suspended)
    deleted_user = create(:user, :deleted)
    # Test a user with no comments
    get :comments, :params => { :display_name => user.display_name }
    assert_response :success
    assert_template :comments
    assert_select "table.table-striped" do
      assert_select "tr", :count => 1 # header, no comments
    end

    # Test a user with a comment
    create(:diary_comment, :user => other_user)

    get :comments, :params => { :display_name => other_user.display_name }
    assert_response :success
    assert_template :comments
    assert_select "table.table-striped" do
      assert_select "tr", :count => 2 # header and one comment
    end

    # Test a suspended user
    get :comments, :params => { :display_name => suspended_user.display_name }
    assert_response :not_found

    # Test a deleted user
    get :comments, :params => { :display_name => deleted_user.display_name }
    assert_response :not_found
  end

  def test_subscribe_success
    user = create(:user)
    other_user = create(:user)
    diary_entry = create(:diary_entry, :user => user)

    assert_difference "diary_entry.subscribers.count", 1 do
      post :subscribe,
           :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name },
           :session => { :user => other_user }
    end
    assert_response :redirect
  end

  def test_subscribe_fail
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)

    # not signed in
    assert_no_difference "diary_entry.subscribers.count" do
      post :subscribe,
           :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name }
    end
    assert_response :forbidden

    # bad diary id
    post :subscribe,
         :params => { :id => 999111, :display_name => "username" },
         :session => { :user => other_user }
    assert_response :not_found

    # trying to subscribe when already subscribed
    post :subscribe,
         :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name },
         :session => { :user => other_user }
    assert_no_difference "diary_entry.subscribers.count" do
      post :subscribe,
           :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name },
           :session => { :user => other_user }
    end
  end

  def test_unsubscribe_success
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)

    post :subscribe,
         :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name },
         :session => { :user => other_user }
    assert_difference "diary_entry.subscribers.count", -1 do
      post :unsubscribe,
           :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name },
           :session => { :user => other_user }
    end
    assert_response :redirect
  end

  def test_unsubscribe_fail
    user = create(:user)
    other_user = create(:user)

    diary_entry = create(:diary_entry, :user => user)

    # not signed in
    assert_no_difference "diary_entry.subscribers.count" do
      post :unsubscribe,
           :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name }
    end
    assert_response :forbidden

    # bad diary id
    post :unsubscribe,
         :params => { :id => 999111, :display_name => "username" },
         :session => { :user => other_user }
    assert_response :not_found

    # trying to unsubscribe when not subscribed
    assert_no_difference "diary_entry.subscribers.count" do
      post :unsubscribe,
           :params => { :id => diary_entry.id, :display_name => diary_entry.user.display_name },
           :session => { :user => other_user }
    end
  end

  private

  def check_diary_index(*entries)
    assert_response :success
    assert_template "index"
    assert_no_missing_translations
    assert_select "div.diary_post", entries.count

    entries.each do |entry|
      assert_select "a[href=?]", "/user/#{ERB::Util.u(entry.user.display_name)}/diary/#{entry.id}"
    end
  end

  def with_diary_feed_delay(value)
    diary_feed_delay = Settings.diary_feed_delay
    Settings.diary_feed_delay = value

    yield

    Settings.diary_feed_delay = diary_feed_delay
  end
end
