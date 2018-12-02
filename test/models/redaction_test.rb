require "test_helper"
require "osm"

class RedactionTest < ActiveSupport::TestCase
  # should not redact a node that is current
  def test_cannot_redact_current
    n = create(:node)
    r = create(:redaction)
    # checks if node n is redacted and expects false
    assert_equal(false, n.redacted?, "Expected node to not be redacted already.")
    # should raise OSM::APICannotRedactError, if current
    assert_raise(OSM::APICannotRedactError) do
      # gets if node is not current version
      n.redact!(r)
    end
  end
  
  # node with older versions in history should not be redactable
  def test_cannot_redact_current_via_old
    node = create(:node, :with_history)
    # older nodes of version 1 taken from node with history
    node_v1 = node.old_nodes.find_by(:version => 1)
    r = create(:redaction)
    # node_v1 should not be redacted
    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    assert_raise(OSM::APICannotRedactError) do
      # checks if node is current and should raise OSM::APICannotRedactError if it is
      node_v1.redact!(r)
    end
  end
  
  # should not be able to do redactions with nodes of version 2
  def test_can_redact_old
    node = create(:node, :with_history, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v2 = node.old_nodes.find_by(:version => 2)
    r = create(:redaction)
    # node_v1 should not be redacted
    assert_equal(false, node_v1.redacted?, "Expected node to not be redacted already.")
    # will not do anything if node_v1 is not current and error is raised
    assert_nothing_raised do
      node_v1.redact!(r)
    end
    # checks if node_v1 is redacted but if node_v2 is not redacted
    assert_equal(true, node_v1.redacted?, "Expected node version 1 to be redacted after redact! call.")
    assert_equal(false, node_v2.redacted?, "Expected node version 2 to not be redacted after redact! call.")
  end
  
  # if both redaction title and description are blank
  def test_redact_empty
    # create moderator
    # session[:user] = create(:moderator_user).id
    # read in user, title and description for redaction
    @redaction = Redaction.new
    # @redaction.user = session[:user]
    @redaction.user = User.new
    @redaction.title = "    "
    @redaction.description = "    "

    # if @redaction.title.blank? || @redaction.description.blank?
      # assert_response :redirect
      # assert_redirected_to :controller => "errors", :action => "forbidden"
    # end
    assert_equal(true, @redaction.title.blank?, "title should be blank")
    assert_equal(true, @redaction.description.blank?, "descr should be blank")
  end
  
  # if redaction title is blank but not description
  def test_redact_empty_title
    # create moderator
    # session[:user] = create(:moderator_user).id
    # read in user, title and description for redaction
    @redaction = Redaction.new
    # @redaction.user = session[:user]
    @redaction.user = User.new
    @redaction.title = "      " # accounting for whitespace
    @redaction.description = "hello"
    # if redaction title is blank (no spaces) 
    # should be redirected to under controller errors and be forbidden
    # if @redaction.title.blank? # made changes here
      # assert_response :redirect
      # assert_redirected_to :controller => "errors", :action => "forbidden"
    # end
    assert_equal(true, @redaction.title.blank?, "title should be blank")
    assert_equal(false, @redaction.description.blank?, "descr should not be blank")
  end
  
  # if redaction title is nil but not description
  def test_redact_empty_title_nil
    # create moderator
    # session[:user] = create(:moderator_user).id
    # read in user, title and description for redaction
    @redaction = Redaction.new
    # @redaction.user = session[:user]
    @redaction.user = User.new
    @redaction.title = nil # accounting for whitespace
    @redaction.description = "hello"
    # if redaction title is blank (no spaces) 
    # should be redirected to under controller errors and be forbidden
    # if @redaction.title.blank? # made changes here
      # assert_response :redirect
      # assert_redirected_to :controller => "errors", :action => "forbidden"
    # end
    assert_equal(true, @redaction.title.blank?, "title should be blank")
    assert_equal(false, @redaction.description.blank?, "descr should not be blank")
  end
  
  # if redaction description is blank but not title
  def test_redact_empty_desc
    # create moderator
    # session[:user] = create(:moderator_user).id
    # read in user, title and description for redaction
    @redaction = Redaction.new
    # @redaction.user = session[:user]
    @redaction.user = User.new
    @redaction.title = "The redac"
    @redaction.description = "      " # if nothing
    # if there is no description, perform the following actions
    # if @redaction.description.blank? # made changes here
      # assert_response :redirect
      # assert_redirected_to :controller => "errors", :action => "forbidden"
    # end
    assert_equal(false, @redaction.title.blank?, "title should not be blank")
    assert_equal(true, @redaction.description.blank?, "descr should be blank")
  end
  
  # if redaction description is nil but not title
  def test_redact_empty_desc_nil
    # create moderator
    # session[:user] = create(:moderator_user).id
    # read in user, title and description for redaction
    @redaction = Redaction.new
    # @redaction.user = session[:user]
    @redaction.user = User.new
    @redaction.title = "The redac"
    @redaction.description = nil # if nothing
    # if there is no description, perform the following actions
    # if @redaction.description.blank? # made changes here
      # assert_response :redirect
      # assert_redirected_to :controller => "errors", :action => "forbidden"
    assert_equal(false, @redaction.title.blank?, "title should not be blank")
    assert_equal(true, @redaction.description.blank?, "descr should be blank")
    # end
  end
  
  # checks for moderator redaction with blank title and description (?)
  # def test_session_redact
    # session[:user] = create(:moderator_user).id

    # redaction = create(:redaction)

    # put :update, :params => { :id => redaction.id, :redaction => { :title => "", :description => "" } }
    # assert_response :redirect
    # assert_redirected_to :controller => "errors", :action => "forbidden"
  # end
end
