require File.dirname(__FILE__) + '/../test_helper'

class DiaryEntryControllerTest < ActionController::TestCase
  fixtures :users, :diary_entries, :diary_comments
  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end
  
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
    
    # Now pass the id, and check that you can edit it
    get(:edit, {:id => diary_entries(:normal_user_entry_1).id}, {'user' => users(:normal_user).id})
    assert_response :success
    assert_select "html:root", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Edit diary entry/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do 
          assert_select "h1", :text => /Edit diary entry/, :count => 1
          assert_select "form[action='/diary_entry/#{diary_entries(:normal_user_entry_1).id}/edit'][method=post]", :count => 1
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
