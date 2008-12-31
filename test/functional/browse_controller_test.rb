require File.dirname(__FILE__) + '/../test_helper'
require 'browse_controller'

class BrowseControllerTest < ActionController::TestCase
  api_fixtures

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end

  # We need to load the home page, then activate the start rjs method
  # and finally check that the new panel has loaded.
  def test_start
  
  end
  
  # This should display the last 20 changesets closed.
  def test_index
    @changesets = Changeset.find(:all, :order => "closed_at DESC", :conditions => ['closed_at < ?', Time.now], :limit=> 20)
    assert @changesets.size <= 20
    get :index
    assert_response :success
    assert_template "index"
    # Now check that all 20 (or however many were returned) changesets are in the html
    assert_select "h2", :text => "#{@changesets.size} Recently Closed Changesets", :count => 1
    assert_select "ul[id='recently_changed'] li a", :count => @changesets.size
    @changesets.each do |changeset|
      if changeset.user.data_public?
        user = changeset.user.display_name
      else
        user = "(anonymous)"
      end
    
      cmt = changeset.tags_as_hash['comment'].to_s
      cmt = "(no comment)" if cmt.length == 0
      text = "#{changeset.id} by #{user} - #{cmt}"
      assert_select "ul[id='recently_changed'] li a[href=/browse/changeset/#{changeset.id}]", :text => text
    end
  end
  
  # Test reading a relation
  def test_read_relation
    
  end
  
  def test_read_relation_history
    
  end
  
  def test_read_way
    
  end
  
  def test_read_way_history
    
  end
  
  def test_read_node
    
  end
  
  def test_read_node_history
    
  end
  
  def test_read_changeset
    
  end
end
