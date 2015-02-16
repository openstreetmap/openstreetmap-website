require 'test_helper'

class DiaryEntryControllerTest < ActionController::TestCase
  fixtures :users, :diary_entries, :diary_comments, :languages

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
  end

  def test_showing_new_diary_entry
    get :new
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/diary/new"
    # Now pretend to login by using the session hash, with the
    # id of the person we want to login as through session(:user)=user.id
    get(:new, nil, 'user' => users(:normal_user).id)
    assert_response :success
    # print @response.body

    # print @response.to_yaml
    assert_select "title", :text => /New Diary Entry/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => "New Diary Entry", :count => 1
    end
    assert_select "div#content", :count => 1 do
      # We don't care about the layout, we just care about the form fields
      # that are available
      assert_select "form[action='/diary/new']", :count => 1 do
        assert_select "input[id=diary_entry_title][name='diary_entry[title]']", :count => 1
        assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :count => 1
        assert_select "input#latitude[name='diary_entry[latitude]'][type=text]", :count => 1
        assert_select "input#longitude[name='diary_entry[longitude]'][type=text]", :count => 1
        assert_select "input[name=commit][type=submit][value=Save]", :count => 1
      end
    end
  end

  def test_editing_diary_entry
    entry = diary_entries(:normal_user_entry_1)

    # Make sure that you are redirected to the login page when you are
    # not logged in, without and with the id of the entry you want to edit
    get :edit, :display_name => entry.user.display_name, :id => entry.id
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/user/#{entry.user.display_name}/diary/#{entry.id}/edit"

    # Verify that you get a not found error, when you pass a bogus id
    get(:edit, { :display_name => entry.user.display_name, :id => 9999 }, { 'user' => entry.user.id })
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => "No entry with the id: 9999", :count => 1
    end

    # Now pass the id, and check that you can edit it, when using the same
    # user as the person who created the entry
    get(:edit, { :display_name => entry.user.display_name, :id => entry.id }, { 'user' => entry.user.id })
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
    post(:edit, { :display_name => entry.user.display_name, :id => entry.id, 'commit' => 'save',
                  'diary_entry' => { 'title' => new_title, 'body' => new_body, 'latitude' => new_latitude,
                                     'longitude' => new_longitude, 'language_code' => new_language_code } },
         { 'user' => entry.user.id })
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => entry.user.display_name, :id => entry.id

    # Now check that the new data is rendered, when logged in
    get :view, { :display_name => entry.user.display_name, :id => entry.id }, { 'user' => entry.user.id }
    assert_response :success
    assert_template 'diary_entry/view'
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
    get :view, { :display_name => entry.user.display_name, :id => entry.id }, { 'user' => entry.user.id }
    assert_response :success
    assert_template 'diary_entry/view'
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

  def test_edit_diary_entry_i18n
    get :edit, { :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id }, { 'user' => users(:normal_user).id }
    assert_response :success
    assert_select "span[class=translation_missing]", false, "Missing translation in edit diary entry"
  end

  def test_create_diary_entry
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
        assert_select "input[name=commit][type=submit][value=Save]", :count => 1
        assert_select "input[name=commit][type=submit][value=Edit]", :count => 1
        assert_select "input[name=commit][type=submit][value=Preview]", :count => 1
        assert_select "input", :count => 7
      end
    end

    # Now try creating a diary entry
    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    new_language_code = "en"
    assert_difference "DiaryEntry.count", 1 do
      post(:new, { 'commit' => 'save',
                   'diary_entry' => { 'title' => new_title, 'body' => new_body, 'latitude' => new_latitude,
                                      'longitude' => new_longitude, 'language_code' => new_language_code } },
           { :user => users(:normal_user).id })
    end
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    entry = DiaryEntry.find(6)
    assert_equal users(:normal_user).id, entry.user_id
    assert_equal new_title, entry.title
    assert_equal new_body, entry.body
    assert_equal new_latitude.to_f, entry.latitude
    assert_equal new_longitude.to_f, entry.longitude
    assert_equal new_language_code, entry.language_code
  end

  def test_creating_diary_comment
    entry = diary_entries(:normal_user_entry_1)

    # Make sure that you are denied when you are not logged in
    post :comment, :display_name => entry.user.display_name, :id => entry.id
    assert_response :forbidden

    # Verify that you get a not found error, when you pass a bogus id
    post :comment, { :display_name => entry.user.display_name, :id => 9999 }, { :user => users(:public_user).id }
    assert_response :not_found
    assert_select "div.content-heading", :count => 1 do
      assert_select "h2", :text => "No entry with the id: 9999", :count => 1
    end

    # Now try again with the right id
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "DiaryComment.count", 1 do
        post :comment, { :display_name => entry.user.display_name, :id => entry.id, :diary_comment => { :body => "New comment" } }, { :user => users(:public_user).id }
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
    comment = DiaryComment.find(5)
    assert_equal entry.id, comment.diary_entry_id
    assert_equal users(:public_user).id, comment.user_id
    assert_equal "New comment", comment.body

    # Now view the diary entry, and check the new comment is present
    get :view, :display_name => entry.user.display_name, :id => entry.id
    assert_response :success
    assert_select ".diary-comment", :count => 1 do
      assert_select "#comment5", :count => 1 do
        assert_select "a[href='/user/#{users(:public_user).display_name}']", :text => users(:public_user).display_name, :count => 1
      end
      assert_select ".richtext", :text => /New comment/, :count => 1
    end
  end

  # Check that you can get the expected response and template for all available languages
  # Should test that there are no <span class="translation_missing">
  def test_listing_diary_entries
    get :list
    assert_response :success, "Should be able to list the diary entries in locale"
    assert_template 'list', "Should use the list template in locale"
    assert_select "span[class=translation_missing]", false, "Missing translation in list of diary entries"

    # Now try to find a specific user's diary entry
    get :list, :display_name => users(:normal_user).display_name
    assert_response :success, "Should be able to list the diary entries for a user in locale"
    assert_template 'list', "Should use the list template for a user in locale"
    assert_no_missing_translations
  end

  def test_rss
    get :rss, :format => :rss
    assert_response :success, "Should be able to get a diary RSS"
    assert_select "rss", :count => 1 do
      assert_select "channel", :count => 1 do
        assert_select "channel>title", :count => 1
        assert_select "image", :count => 1
        assert_select "channel>item", :count => 2
      end
    end
  end

  def test_rss_language
    get :rss, :language => diary_entries(:normal_user_entry_1).language_code, :format => :rss
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 1 # , "Diary entries should be filtered by language"
  end

  #  def test_rss_nonexisting_language
  #    get :rss, {:language => 'xx', :format => :rss}
  #    assert_response :not_found, "Should not be able to get a nonexisting language diary RSS"
  #  end

  def test_rss_language_with_no_entries
    get :rss, :language => 'sl', :format => :rss
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 0 # , "Diary entries should be filtered by language"
  end

  def test_rss_user
    get :rss, :display_name => users(:normal_user).display_name, :format => :rss
    assert_response :success, "Should be able to get a specific users diary RSS"
    assert_select "rss>channel>item", :count => 2 # , "Diary entries should be filtered by user"
  end

  def test_rss_nonexisting_user
    # Try a user that has never existed
    get :rss, :display_name => 'fakeUsername76543', :format => :rss
    assert_response :not_found, "Should not be able to get a nonexisting users diary RSS"

    # Try a suspended user
    get :rss, :display_name => users(:suspended_user).display_name, :format => :rss
    assert_response :not_found, "Should not be able to get a suspended users diary RSS"

    # Try a deleted user
    get :rss, :display_name => users(:deleted_user).display_name, :format => :rss
    assert_response :not_found, "Should not be able to get a deleted users diary RSS"
  end

  def test_viewing_diary_entry
    # Try a normal entry that should work
    get :view, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id
    assert_response :success
    assert_template :view

    # Try a deleted entry
    get :view, :display_name => users(:normal_user).display_name, :id => diary_entries(:deleted_entry).id
    assert_response :not_found

    # Try an entry by a suspended user
    get :view, :display_name => users(:suspended_user).display_name, :id => diary_entries(:entry_by_suspended_user).id
    assert_response :not_found

    # Try an entry by a deleted user
    get :view, :display_name => users(:deleted_user).display_name, :id => diary_entries(:entry_by_deleted_user).id
    assert_response :not_found
  end

  def test_viewing_hidden_comments
    # Get a diary entry that has hidden comments
    get :view, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_geo_entry).id
    assert_response :success
    assert_template :view
    assert_select "div.comments" do
      assert_select "p#comment1", :count => 1 # visible comment
      assert_select "p#comment2", :count => 0 # comment by suspended user
      assert_select "p#comment3", :count => 0 # comment by deleted user
      assert_select "p#comment4", :count => 0 # hidden comment
    end
  end

  def test_hide
    # Try without logging in
    post :hide, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id
    assert_response :forbidden
    assert_equal true, DiaryEntry.find(diary_entries(:normal_user_entry_1).id).visible

    # Now try as a normal user
    post :hide, { :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id
    assert_equal true, DiaryEntry.find(diary_entries(:normal_user_entry_1).id).visible

    # Finally try as an administrator
    post :hide, { :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id }, { :user => users(:administrator_user).id }
    assert_response :redirect
    assert_redirected_to :action => :list, :display_name => users(:normal_user).display_name
    assert_equal false, DiaryEntry.find(diary_entries(:normal_user_entry_1).id).visible
  end

  def test_hidecomment
    # Try without logging in
    post :hidecomment, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_geo_entry).id, :comment => diary_comments(:comment_for_geo_post).id
    assert_response :forbidden
    assert_equal true, DiaryComment.find(diary_comments(:comment_for_geo_post).id).visible

    # Now try as a normal user
    post :hidecomment, { :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_geo_entry).id, :comment => diary_comments(:comment_for_geo_post).id }, { :user => users(:normal_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_geo_entry).id
    assert_equal true, DiaryComment.find(diary_comments(:comment_for_geo_post).id).visible

    # Finally try as an administrator
    post :hidecomment, { :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_geo_entry).id, :comment => diary_comments(:comment_for_geo_post).id }, { :user => users(:administrator_user).id }
    assert_response :redirect
    assert_redirected_to :action => :view, :display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_geo_entry).id
    assert_equal false, DiaryComment.find(diary_comments(:comment_for_geo_post).id).visible
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
end
