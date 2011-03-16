require File.dirname(__FILE__) + '/../test_helper'

class DiaryEntryControllerTest < ActionController::TestCase
  fixtures :users, :diary_entries, :diary_comments, :languages

  include ActionView::Helpers::NumberHelper

  def test_showing_new_diary_entry
    get :new
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/diary/new"
    # Now pretend to login by using the session hash, with the 
    # id of the person we want to login as through session(:user)=user.id
    get(:new, nil, {'user' => users(:normal_user).id})
    assert_response :success
    #print @response.body
    
    #print @response.to_yaml
    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /New Diary Entry/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "h1", "New Diary Entry", :count => 1
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
    end
        
  end
  
  def test_editing_diary_entry
    # Make sure that you are redirected to the login page when you are 
    # not logged in, without and with the id of the entry you want to edit
    get :edit
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/diary_entry/edit"
    
    get :edit, :id => diary_entries(:normal_user_entry_1).id
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/diary_entry/edit"
    
    # Verify that you get a not found error, when you don't pass an id
    get(:edit, nil, {'user' => users(:normal_user).id})
    assert_response :not_found
    assert_select "html", :count => 1 do
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "h2", :text => "No entry with the id:", :count => 1 
        end
      end
    end
    
    # Now pass the id, and check that you can edit it, when using the same 
    # user as the person who created the entry
    get(:edit, {:id => diary_entries(:normal_user_entry_1).id}, {'user' => users(:normal_user).id})
    assert_response :success
    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Edit diary entry/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do 
          assert_select "h1", :text => /Edit diary entry/, :count => 1
          assert_select "form[action='/diary_entry/#{diary_entries(:normal_user_entry_1).id}/edit'][method=post]", :count => 1 do
            assert_select "input#diary_entry_title[name='diary_entry[title]'][value='#{diary_entries(:normal_user_entry_1).title}']", :count => 1
            assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :text => diary_entries(:normal_user_entry_1).body, :count => 1
            assert_select "select#diary_entry_language_code", :count => 1
            assert_select "input#latitude[name='diary_entry[latitude]']", :count => 1
            assert_select "input#longitude[name='diary_entry[longitude]']", :count => 1
            assert_select "input[name=commit][type=submit][value=Save]", :count => 1
            assert_select "input", :count => 5
          end
        end
      end
    end
    
    # Now lets see if you can edit the diary entry
    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    new_language_code = "en"
    post(:edit, {:id => diary_entries(:normal_user_entry_1).id, 'commit' => 'save', 
      'diary_entry'=>{'title' => new_title, 'body' => new_body, 'latitude' => new_latitude,
      'longitude' => new_longitude, 'language_code' => new_language_code} },
         {'user' => users(:normal_user).id})
    assert_response :redirect
    assert_redirected_to :action => :view, :id => diary_entries(:normal_user_entry_1).id
    
    # Now check that the new data is rendered, when logged in
    get :view, {:id => diary_entries(:normal_user_entry_1).id, :display_name => 'test'}, {'user' => users(:normal_user).id}
    assert_response :success
    assert_template 'diary_entry/view'
    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Users' diaries | /, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "h2", :text => /#{users(:normal_user).display_name}'s diary/, :count => 1
          assert_select "b", :text => /#{new_title}/, :count => 1
          # This next line won't work if the text has been run through the htmlize function
          # due to formatting that could be introduced
          assert_select "p", :text => /#{new_body}/, :count => 1
          assert_select "abbr[class=geo][title=#{number_with_precision(new_latitude, :precision => 4)}; #{number_with_precision(new_longitude, :precision => 4)}]", :count => 1
          # As we're not logged in, check that you cannot edit
          #print @response.body
          assert_select "a[href='/user/#{users(:normal_user).display_name}/diary/#{diary_entries(:normal_user_entry_1).id}/edit']", :text => "Edit this entry", :count => 1
        end
      end
    end
    
    # and when not logged in as the user who wrote the entry
    get :view, {:id => diary_entries(:normal_user_entry_1).id, :display_name => 'test'}, {'user' => users(:public_user).id}
    assert_response :success
    assert_template 'diary_entry/view'
    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Users' diaries | /, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "h2", :text => /#{users(:normal_user).display_name}'s diary/, :count => 1
          assert_select "b", :text => /#{new_title}/, :count => 1
          # This next line won't work if the text has been run through the htmlize function
          # due to formatting that could be introduced
          assert_select "p", :text => /#{new_body}/, :count => 1
          assert_select "abbr[class=geo][title=#{number_with_precision(new_latitude, :precision => 4)}; #{number_with_precision(new_longitude, :precision => 4)}]", :count => 1
          # As we're not logged in, check that you cannot edit
          assert_select "span[class=hidden show_if_user_#{users(:normal_user).id}]", :count => 1 do
            assert_select "a[href='/user/#{users(:normal_user).display_name}/diary/#{diary_entries(:normal_user_entry_1).id}/edit']", :text => "Edit this entry", :count => 1
          end
        end
      end
    end
    #print @response.body
    
  end
  
  def test_edit_diary_entry_i18n
    get(:edit, {:id => diary_entries(:normal_user_entry_1).id}, {'user' => users(:normal_user).id})
    assert_response :success
    assert_select "span[class=translation_missing]", false, "Missing translation in edit diary entry"
  end
  
  def test_create_diary_entry
    #post :new
  end
  
  def test_creating_diary_comment
    
  end
  
  # Check that you can get the expected response and template for all available languages
  # Should test that there are no <span class="translation_missing">
  def test_listing_diary_entries
      get :list
      assert_response :success, "Should be able to list the diary entries in locale"
      assert_template 'list', "Should use the list template in locale"
      assert_select "span[class=translation_missing]", false, "Missing translation in list of diary entries"
    
      # Now try to find a specific user's diary entry
      get :list, {:display_name => users(:normal_user).display_name}
      assert_response :success, "Should be able to list the diary entries for a user in locale"
      assert_template 'list', "Should use the list template for a user in locale"
      assert_no_missing_translations
  end
  
  def test_rss
    get :rss, {:format => :rss}
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
    get :rss, {:language => diary_entries(:normal_user_entry_1).language_code, :format => :rss}
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 1 #, "Diary entries should be filtered by language"
  end
  
#  def test_rss_nonexisting_language
#    get :rss, {:language => 'xx', :format => :rss}
#    assert_response :not_found, "Should not be able to get a nonexisting language diary RSS"
#  end

  def test_rss_language_with_no_entries
    get :rss, {:language => 'sl', :format => :rss}
    assert_response :success, "Should be able to get a specific language diary RSS"
    assert_select "rss>channel>item", :count => 0 #, "Diary entries should be filtered by language"
  end

  def test_rss_user
    get :rss, {:display_name => users(:normal_user).display_name, :format => :rss}
    assert_response :success, "Should be able to get a specific users diary RSS"
    assert_select "rss>channel>item", :count => 2 #, "Diary entries should be filtered by user"
  end
  
  def test_rss_nonexisting_user
    get :rss, {:display_name => 'fakeUsername76543', :format => :rss}
    assert_response :not_found, "Should not be able to get a nonexisting users diary RSS"
  end

  def test_viewing_diary_entry
    get :view, {:display_name => users(:normal_user).display_name, :id => diary_entries(:normal_user_entry_1).id}
    assert_response :success
    assert_template 'view'
  end
end
