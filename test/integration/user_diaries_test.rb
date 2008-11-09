require 'test_helper'

class UserDiariesTest < ActionController::IntegrationTest
  fixtures :users, :diary_entries

  def test_showing_create_diary_entry
    get '/user/test/diary/new'
    assert_response 302
    assert_redirected_to :controller => :user, :action => "login", :referer => "/user/test/diary/new"
    #follow_redirect
    # Now login
    #post  :login, :user_email => "test@openstreetmap.org", :user_password => "test"
    #
    #get :controller => :users, :action => :new
    #assert_response :success
    #print @response.to_yaml
    #assert_select "html" do
    #  assert_select "body" do
    #    assert_select "div#content" do
    #      assert_select "form" do
    #        assert_select "input[id=diary_entry_title]"
    #      end
    #    end
    #  end
    #end
        
  end
end
