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
  end

  def test_map_bug_comment_create_success
    assert_difference('MapBugComment.count') do
        post :edit_bug, {:id => 2, :name => "new_tester", :text => "This is an additional comment"}
    end
    assert_response :success      
  end

  def test_map_bug_read_success
    get :read, {:id => 1}
    assert_response :success      
  end

  def test_map_bug_read_xml_success
    get :read, {:id => 1,  :format => 'xml'}
    assert_response :success      
  end

  def test_map_bug_read_rss_success
    get :read, {:id => 1,  :format => 'rss'}
    assert_response :success      
  end

  def test_map_bug_read_json_success
    get :read, {:id => 1,  :format => 'json'}
    assert_response :success      
  end

  def test_map_bug_read_gpx_success
    get :read, {:id => 1,  :format => 'gpx'}
    assert_response :success
  end

  def test_map_bug_close_success
	post :close_bug, {:id => 2}
    assert_response :success      
  end

  def test_get_bugs_success
	get :get_bugs, {:bbox=>'1,1,1.2,1.2'}
	assert_response :success
  end

  def test_get_bugs_large_area_success
	get :get_bugs, {:bbox=>'-10,-10,12,12'}
	assert_response :success
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

  def test_get_bugs_rss_success
	get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'rss'}
	assert_response :success
  end

  def test_get_bugs_json_success
	get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'json'}
	assert_response :success
  end

  def test_get_bugs_xml_success
	get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'xml'}
	assert_response :success
  end

  def test_get_bugs_gpx_success
	get :get_bugs, {:bbox=>'1,1,1.2,1.2', :format => 'gpx'}
	assert_response :success
  end



  def test_search_success
	get :search, {:bbox=>'1,1,1.2,1.2', :q => 'bug 1'}
	assert_response :success
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

  
end
