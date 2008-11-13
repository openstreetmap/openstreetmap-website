require File.dirname(__FILE__) + '/../test_helper'

class DiaryEntryControllerTest < ActionController::TestCase
  fixtures :users, :diary_entries, :diary_comments

  def test_showing_new_diary_entry
    get :new
    assert_response :redirect
    assert_redirected_to :controller => :user, :action => "login", :referer => "/diary_entry/new"
    # Now pretend to login by using the session hash, with the 
    # id of the person we want to login as through session(:user)=user.id
    get(:new, nil, {'user' => users(:normal_user).id})
    assert_response :success
    #print @response.body
    
    #print @response.to_yaml
    assert_select "html:root", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /New diary entry/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "h1", "New diary entry", :count => 1
          # We don't care about the layout, we just care about the form fields
          # that are available
          assert_select "form[action='/diary_entry/new']", :count => 1 do
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
    assert_select "html:root", :count => 1 do
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
    assert_select "html:root", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Edit diary entry/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do 
          assert_select "h1", :text => /Edit diary entry/, :count => 1
          assert_select "form[action='/diary_entry/#{diary_entries(:normal_user_entry_1).id}/edit'][method=post]", :count => 1 do
            assert_select "input#diary_entry_title[name='diary_entry[title]'][value='#{diary_entries(:normal_user_entry_1).title}']", :count => 1
            assert_select "textarea#diary_entry_body[name='diary_entry[body]']", :text => diary_entries(:normal_user_entry_1).body, :count => 1
            assert_select "input#latitude[name='diary_entry[latitude]']", :count => 1
            assert_select "input#longitude[name='diary_entry[longitude]']", :count => 1
            assert_select "input[name=commit][type=submit][value=Save]", :count => 1
            assert_select "input", :count => 4
          end
        end
      end
    end
    
    # Now lets see if you can edit the diary entry
    new_title = "New Title"
    new_body = "This is a new body for the diary entry"
    new_latitude = "1.1"
    new_longitude = "2.2"
    post(:edit, {:id => diary_entries(:normal_user_entry_1).id, 'commit' => 'save', 
      'diary_entry'=>{'title' => new_title, 'body' => new_body, 'latitude' => new_latitude, 'longitude' => new_longitude} },
         {'user' => users(:normal_user).id})
    assert_response :redirect
    assert_redirected_to :action => :view, :id => diary_entries(:normal_user_entry_1).id
    
    # Now check that the new data is rendered, when logged in
    get :view, {:id => diary_entries(:normal_user_entry_1).id, :display_name => 'test'}, {'user' => users(:normal_user).id}
    assert_response :success
    assert_template 'diary_entry/view'
    assert_select "html:root", :count => 1 do
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
          assert_select "span.latitude", :text => new_latitude, :count => 1
          assert_select "span.longitude", :text => new_longitude, :count => 1
          # As we're not logged in, check that you cannot edit
          #print @response.body
          assert_select "a[href='/user/#{users(:normal_user).display_name}/diary/#{diary_entries(:normal_user_entry_1).id}/edit']", :text => "Edit this entry", :count => 1
        end
      end
    end
    
    # and when not logged in as the user who wrote the entry
    get :view, {:id => diary_entries(:normal_user_entry_1).id, :display_name => 'test'}, {'user' => users(:second_user).id}
    assert_response :success
    assert_template 'diary_entry/view'
    assert_select "html:root", :count => 1 do
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
          assert_select "span.latitude", :text => new_latitude, :count => 1
          assert_select "span.longitude", :text => new_longitude, :count => 1
          # As we're not logged in, check that you cannot edit
          assert_select "a[href='/user/#{users(:normal_user).display_name}/diary/#{diary_entries(:normal_user_entry_1).id}/edit']", :text => "Edit this entry", :count => 0
        end
      end
    end
    #print @response.body
    
  end
  
  def test_editing_creating_diary_comment
    
  end
  
  def test_listing_diary_entries
    
  end
  
  def test_rss
    get :rss
    assert :success
    
  end
  
  def test_viewing_diary_entry
    
  end
end
