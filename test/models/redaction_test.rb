require "test_helper"
require "osm"

class RedactionTest < ActiveSupport::TestCase
  def test_cannot_redact_current
    n = create(:node)
    r = create(:redaction)
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      n.redact!(r)
    end
  end

  def test_cannot_redact_current_via_old
    node = create(:node, :with_history)
    node_v1 = node.old_nodes.find_by(:version => 1)
    r = create(:redaction)
    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      node_v1.redact!(r)
    end
  end

  def test_can_redact_old
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    r = create(:redaction)

    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    assert_nothing_raised do
      node_v1.redact!(r)
    end
    assert_equal(true, node_v1.redacted?, "Expected node version 1 to be redacted after redact! call.")
    assert_equal(false, node_v2.redacted?, "Expected node version 2 to not be redacted after redact! call.")
  end
  def test_redact_empty
  #create moderator
  session[:user] = create(:moderator_user).id
  # read in user, title and description for redaction
  @redaction = Redaction.new
  @redaction.user = session[:user]
  @redaction.title = ""
  @redaction.description = ""

  if !@redaction.title == "" || !@redaction.description  == ""
      assert_response :redirect
      assert_redirected_to :controller => "errors", :action => "forbidden"

end

def test_redact_empty_title
  #create moderator
  session[:user] = create(:moderator_user).id
  # read in user, title and description for redaction
  @redaction = Redaction.new
  @redaction.user = session[:user]
  @redaction.title = ""
  @redaction.description = "hello"

  if !@redaction.title == "" || !@redaction.description  == "hello"
      assert_response :redirect
      assert_redirected_to :controller => "errors", :action => "forbidden"

end

def test_redact_empty_desc
  #create moderator
  session[:user] = create(:moderator_user).id
  # read in user, title and description for redaction
  @redaction = Redaction.new
  @redaction.user = session[:user]
  @redaction.title = "The redac"
  @redaction.description = ""

  if !@redaction.title == "The redac" || !@redaction.description  == ""
      assert_response :redirect
      assert_redirected_to :controller => "errors", :action => "forbidden"

end

def test_session_redact
  session[:user] = create(:moderator_user).id

  redaction = create(:redaction)

  put :update, :params => { :id => redaction.id, :redaction => { :title => "", :description => "" } }
  assert_response :redirect
  assert_redirected_to :controller => "errors", :action => "forbidden"
end

end
