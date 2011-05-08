require File.dirname(__FILE__) + '/../test_helper'

class MapBugsControllerTest < ActionController::TestCase
  fixtures :users, :map_bugs, :map_bug_comment
    
  def test_map_bug_create_success
    assert_difference('MapBug.count') do
      assert_difference('MapBugComment.count') do
        post :add_bug, {:lat => -1.0, :lon => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :success
    id = @response.body.sub(/ok/,"").to_i
    get :read, {:id => id, :format => 'json'}
    assert_response :success
    js = @response.body
    assert_match "\"status\":\"open\"", js
    assert_match "\"comment\":\"This is a comment\"", js
    assert_match "\"commenter_name\":\"new_tester (a)\"", js
  end

  def test_map_bug_comment_create_success
    assert_difference('MapBugComment.count') do
      post :edit_bug, {:id => 2, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :success

    get :read, {:id => 2, :format => 'json'}
    assert_response :success
    js = @response.body
    assert_match "\"id\":2", js
    assert_match "\"status\":\"open\"", js
    assert_match "\"comment\":\"This is an additional comment\"", js
    assert_match "\"commenter_name\":\"new_tester2 (a)\"", js
  end

  def test_map_bug_read_success
    get :read, {:id => 1}
    assert_response :success      

    get :read, {:id => 1,  :format => 'xml'}
    assert_response :success

    get :read, {:id => 1,  :format => 'rss'}
    assert_response :success

    get :read, {:id => 1,  :format => 'json'}
    assert_response :success

    get :read, {:id => 1,  :format => 'gpx'}
    assert_response :success
  end

  def test_map_bug_close_success
    post :close_bug, {:id => 2}
    assert_response :success

    get :read, {:id => 2, :format => 'json'}
    js = @response.body
    assert_match "\"id\":2", js
    assert_match "\"status\":\"closed\"", js
  end

  def test_get_bugs_success
    get :get_bugs, {:bbox=>'1,1,1.2,1.2'}
    assert_response :success

    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'rss'}
    assert_response :success

    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'json'}
    assert_response :success

    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'xml'}
    assert_response :success

    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'gpx'}
    assert_response :success
  end

  def test_get_bugs_large_area_success
    get :get_bugs, {:bbox=>'-2.5,-2.5,2.5,2.5'}
    assert_response :success
  end

  def test_get_bugs_large_area_bad_request
    get :get_bugs, {:bbox=>'-10,-10,12,12'}
    assert_response :bad_request
  end

  def test_get_bugs_closed_7_success
    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :closed => '7'}
    assert_response :success
  end

  def test_get_bugs_closed_0_success
    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :closed => '0'}
    assert_response :success
  end

  def test_get_bugs_closed_n1_success
    get :get_bugs, {:bbox=>'1,1,1.2,1.2', :closed => '-1'}
    assert_response :success
  end


  def test_search_success
    get :search, {:bbox=>'1,1,1.2,1.2', :q => 'bug 1'}
    assert_response :success

    get :search, {:bbox=>'1,1,1.2,1.2', :q => 'bug 1', :format => 'xml'}
    assert_response :success

    get :search, {:bbox=>'1,1,1.2,1.2', :q => 'bug 1', :format => 'json'}
    assert_response :success

    get :search, {:bbox=>'1,1,1.2,1.2', :q => 'bug 1', :format => 'rss'}
    assert_response :success

    get :search, {:bbox=>'1,1,1.2,1.2', :q => 'bug 1', :format => 'gpx'}
    assert_response :success
  end

  def test_rss_success
    get :rss, {:bbox=>'1,1,1.2,1.2'}
    assert_response :success
	
    get :rss
    assert_response :success
  end

  def test_user_bugs_success
    get :my_bugs, {:display_name=>'test'}
    assert_response :success

    get :my_bugs, {:display_name=>'pulibc_test2'}
    assert_response :success

    get :my_bugs, {:display_name=>'non-existent'}
    assert_response :not_found	
  end

  def test_map_bug_comment_create_not_found
    assert_no_difference('MapBugComment.count') do
      post :edit_bug, {:id => 12345, :name => "new_tester", :text => "This is an additional comment"}
    end
    assert_response :not_found
  end

  def test_map_bug_close_not_found
    post :close_bug, {:id => 12345}
    assert_response :not_found
  end

  def test_map_bug_read_not_found
    get :read, {:id => 12345}
    assert_response :not_found
  end

  def test_map_bug_read_gone
    get :read, {:id => 4}
    assert_response :gone
  end

  def test_map_bug_hidden_comment
    get :read, {:id => 5, :format => 'json'}
    assert_response :success
    js = @response.body
    assert_match "\"id\":5", js
    assert_match "\"comment\":\"Valid comment for bug 5\"", js
    assert_match "\"comment\":\"Another valid comment for bug 5\"", js
    assert_no_match /\"comment\":\"Spam for bug 5\"/, js
  end
end
