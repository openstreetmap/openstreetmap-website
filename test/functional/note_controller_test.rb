require File.dirname(__FILE__) + '/../test_helper'

class NoteControllerTest < ActionController::TestCase
  fixtures :users, :notes, :note_comments

  def test_note_create_success
    assert_difference('Note.count') do
      assert_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :success
    id = @response.body.sub(/ok/,"").to_i

    get :read, {:id => id, :format => 'json'}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal id, js["note"]["id"]
    assert_equal "open", js["note"]["status"]
    assert_equal "opened", js["note"]["comments"].last["event"]
    assert_equal "This is a comment", js["note"]["comments"].last["body"]
    assert_equal "new_tester (a)", js["note"]["comments"].last["author_name"]
  end

  def test_note_create_fail
    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lon => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0, :name => "new_tester"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -100.0, :lon => -1.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -200.0, :name => "new_tester", :text => "This is a comment"}
      end
    end
    assert_response :bad_request
  end

  def test_note_comment_create_success
    assert_difference('NoteComment.count') do
      post :update, {:id => notes(:open_note_with_comment).id, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :success

    get :read, {:id => notes(:open_note_with_comment).id, :format => 'json'}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal notes(:open_note_with_comment).id, js["note"]["id"]
    assert_equal "open", js["note"]["status"]
    assert_equal "commented", js["note"]["comments"].last["event"]
    assert_equal "This is an additional comment", js["note"]["comments"].last["body"]
    assert_equal "new_tester2 (a)", js["note"]["comments"].last["author_name"]
  end

  def test_note_comment_create_fail
    assert_no_difference('NoteComment.count') do
      post :update, {:name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :update, {:id => notes(:open_note_with_comment).id, :name => "new_tester2"}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :update, {:id => 12345, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :not_found

    assert_no_difference('NoteComment.count') do
      post :update, {:id => notes(:hidden_note_with_comment).id, :name => "new_tester2", :text => "This is an additional comment"}
    end
    assert_response :gone
  end

  def test_note_close_success
    post :close, {:id => notes(:open_note_with_comment).id}
    assert_response :success

    get :read, {:id => notes(:open_note_with_comment).id, :format => 'json'}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal notes(:open_note_with_comment).id, js["note"]["id"]
    assert_equal "closed", js["note"]["status"]
    assert_equal "closed", js["note"]["comments"].last["event"]
    assert_equal "NoName (a)", js["note"]["comments"].last["author_name"]
  end

  def test_note_close_fail
    post :close
    assert_response :bad_request

    post :close, {:id => 12345}
    assert_response :not_found

    post :close, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_note_read_success
    get :read, {:id => notes(:open_note).id}
    assert_response :success      
    assert_equal "application/xml", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "xml"}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "rss"}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "json"}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :read, {:id => notes(:open_note).id, :format => "gpx"}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_note_read_hidden_comment
    get :read, {:id => notes(:note_with_hidden_comment).id, :format => 'json'}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal notes(:note_with_hidden_comment).id, js["note"]["id"]
    assert_equal 2, js["note"]["comments"].count
    assert_equal "Valid comment for note 5", js["note"]["comments"][0]["body"]
    assert_equal "Another valid comment for note 5", js["note"]["comments"][1]["body"]
  end

  def test_note_read_fail
    post :read
    assert_response :bad_request

    get :read, {:id => 12345}
    assert_response :not_found

    get :read, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_note_delete_success
    delete :delete, {:id => notes(:open_note_with_comment).id}
    assert_response :success

    get :read, {:id => notes(:open_note_with_comment).id, :format => 'json'}
    assert_response :gone
  end

  def test_note_delete_fail
    delete :delete
    assert_response :bad_request

    delete :delete, {:id => 12345}
    assert_response :not_found

    delete :delete, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_get_notes_success
    get :list, {:bbox => '1,1,1.2,1.2'}
    assert_response :success
    assert_equal "text/javascript", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'rss'}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'xml'}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :list, {:bbox => '1,1,1.2,1.2', :format => 'gpx'}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_get_notes_large_area
    get :list, {:bbox => '-2.5,-2.5,2.5,2.5'}
    assert_response :success

    get :list, {:l => '-2.5', :b => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :success

    get :list, {:bbox => '-10,-10,12,12'}
    assert_response :bad_request

    get :list, {:l => '-10', :b => '-10', :r => '12', :t => '12'}
    assert_response :bad_request
  end

  def test_get_notes_closed
    get :list, {:bbox=>'1,1,1.7,1.7', :closed => '7', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal 4, js.count

    get :list, {:bbox=>'1,1,1.7,1.7', :closed => '0', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal 4, js.count

    get :list, {:bbox=>'1,1,1.7,1.7', :closed => '-1', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal 6, js.count
  end

  def test_get_notes_bad_params
    get :list, {:bbox => '-2.5,-2.5,2.5'}
    assert_response :bad_request

    get :list, {:bbox => '-2.5,-2.5,2.5,2.5,2.5'}
    assert_response :bad_request

    get :list, {:b => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :bad_request

    get :list, {:l => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :bad_request

    get :list, {:l => '-2.5', :b => '-2.5', :t => '2.5'}
    assert_response :bad_request

    get :list, {:l => '-2.5', :b => '-2.5', :r => '2.5'}
    assert_response :bad_request
  end

  def test_search_success
    get :search, {:q => 'note 1'}
    assert_response :success
    assert_equal "text/javascript", @response.content_type

    get :search, {:q => 'note 1', :format => 'xml'}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :search, {:q => 'note 1', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :search, {:q => 'note 1', :format => 'rss'}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :search, {:q => 'note 1', :format => 'gpx'}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_search_bad_params
    get :search
    assert_response :bad_request
  end

  def test_rss_success
    get :rss
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :rss, {:bbox=>'1,1,1.2,1.2'}
    assert_response :success	
    assert_equal "application/rss+xml", @response.content_type
  end

  def test_rss_fail
    get :rss, {:bbox=>'1,1,1.2'}
    assert_response :bad_request

    get :rss, {:bbox=>'1,1,1.2,1.2,1.2'}
    assert_response :bad_request
  end

  def test_user_notes_success
    get :mine, {:display_name=>'test'}
    assert_response :success

    get :mine, {:display_name=>'pulibc_test2'}
    assert_response :success

    get :mine, {:display_name=>'non-existent'}
    assert_response :not_found	
  end
end
