require File.dirname(__FILE__) + '/../test_helper'
require 'app/controllers/user_controller.rb'

class DiaryEntryControllerTest < ActionController::TestCase
  fixtures :users, :diary_entries, :diary_comments
  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end
  
  def test_showing_create_diary_entry
    get :new
    assert_response 302
    assert_redirected_to :controller => :user, :action => "login", :referer => "/diary_entry/new"
    # Now pretend to login by using the session hash, with the 
    # id of the person we want to login as through session(:user)=user.id
    get(:new, nil, {'user' => users(:normal_user).id})
    assert_response :success
    #print @response.body
        
    #print @response.to_yaml
    assert_select "html" do
      assert_select "body" do
        assert_select "div#content" do
          assert_select "form" do
            assert_select "input[id=diary_entry_title]"
          end
        end
      end
    end
        
  end
  
  def test_editing_diary_entry
    get :edit
    assert :not_authorized
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
