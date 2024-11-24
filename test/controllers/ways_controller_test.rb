require "test_helper"

class WaysControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/way/1", :method => :get },
      { :controller => "ways", :action => "show", :id => "1" }
    )
  end

  def test_show
    way = create(:way)
    sidebar_browse_check :way_path, way.id, "browse/feature"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 0
  end

  def test_show_multiple_versions
    way = create(:way, :with_history, :version => 2)
    sidebar_browse_check :way_path, way.id, "browse/feature"
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 2}']", :count => 1
  end

  def test_show_relation_member
    member = create(:way)
    relation = create(:relation)
    create(:relation_member, :relation => relation, :member => member)
    sidebar_browse_check :way_path, member.id, "browse/feature"
    assert_select "a[href='#{relation_path relation}']", :count => 1
  end

  def test_show_timeout
    way = create(:way)
    with_settings(:web_timeout => -1) do
      get way_path(way)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the way with the id #{way.id}")}/
  end

  def test_show_nodes_collapsed
    way = create(:way_with_nodes, :nodes_count => 2)

    get way_path(way, :xhr => true)
    assert_response :success
    assert_dom "ul:has(> li a[href='#{node_path way.nodes[0]}']):has(> li a[href='#{node_path way.nodes[0]}'])", :count => 1 do
      assert_dom "> li", :count => 1 do |list_items|
        assert_dom list_items, "a[href='#{node_path way.nodes[0]}']"
        assert_dom list_items, "a[href='#{node_path way.nodes[1]}']"
      end
    end
  end

  def test_show_nodes_separate
    way = create(:way_with_nodes, :nodes_count => 2)
    create(:node_tag, :node => way.nodes[0], :k => "name", :v => "Distinct Node 0")
    create(:node_tag, :node => way.nodes[1], :k => "name", :v => "Distinct Node 1")

    get way_path(way, :xhr => true)
    assert_response :success
    assert_dom "ul:has(> li a[href='#{node_path way.nodes[0]}']):has(> li a[href='#{node_path way.nodes[0]}'])", :count => 1 do
      assert_dom "> li", :count => 2 do |list_items|
        assert_dom list_items[0], "a[href='#{node_path way.nodes[0]}']"
        assert_dom list_items[1], "a[href='#{node_path way.nodes[1]}']"
      end
    end
  end

  ##
  # shows another way that shares a node
  #
  # (b)--1--(a)--2--(c)
  #
  def test_show_nodes_also_part_of_way
    way1 = create(:way)
    way2 = create(:way)
    node_a = create(:node)
    node_b = create(:node)
    node_c = create(:node)
    create(:way_node, :way => way1, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way1, :node => node_b, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way2, :node => node_c, :sequence_id => 2)

    get way_path(way1, :xhr => true)
    assert_response :success
    assert_dom "ul:has(> li a[href='#{node_path node_a}']):has(> li a[href='#{node_path node_b}'])", :count => 1 do
      assert_dom "> li", :count => 2 do |list_items|
        assert_dom list_items[0], "a[href='#{node_path node_a}']"
        assert_dom list_items[1], "a[href='#{node_path node_b}']"
        assert_dom list_items[1], "ul", :count => 0
        assert_dom list_items[0], "ul", :count => 1 do
          assert_dom "> li", :count => 1 do |sub_list_items|
            assert_dom sub_list_items[0], "a[href='#{way_path way2}']"
          end
        end
      end
    end
  end

  ##
  # node shared with a looped way shouldn't cause that way appear twice in the "part of ways" sublist
  #
  # (b)--1--(a)--2--(c)
  #           \    /
  #            \  /
  #            (d)
  #
  def test_show_nodes_also_part_of_looped_way
    way1 = create(:way)
    way2 = create(:way)
    node_a = create(:node)
    node_b = create(:node)
    node_c = create(:node)
    node_d = create(:node)
    create(:way_node, :way => way1, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way1, :node => node_b, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way2, :node => node_c, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_d, :sequence_id => 3)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 4)

    get way_path(way1, :xhr => true)
    assert_response :success
    assert_dom "ul:has(> li a[href='#{node_path node_a}']):has(> li a[href='#{node_path node_b}'])", :count => 1 do
      assert_dom "> li", :count => 2 do |list_items|
        assert_dom list_items[0], "a[href='#{node_path node_a}']"
        assert_dom list_items[1], "a[href='#{node_path node_b}']"
        assert_dom list_items[1], "ul", :count => 0
        assert_dom list_items[0], "ul", :count => 1 do
          assert_dom "> li", :count => 1 do |sub_list_items|
            assert_dom sub_list_items[0], "a[href='#{way_path way2}']"
          end
        end
      end
    end
  end

  ##
  # shows two ways that share a node
  #
  # (b)--1--(a)--2--(c)
  #           \
  #            3
  #             \
  #             (d)
  #
  def test_show_nodes_also_part_of_2_ways
    way1 = create(:way)
    way2 = create(:way)
    way3 = create(:way)
    node_a = create(:node)
    node_b = create(:node)
    node_c = create(:node)
    node_d = create(:node)
    create(:way_node, :way => way1, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way1, :node => node_b, :sequence_id => 2)
    create(:way_node, :way => way2, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way2, :node => node_c, :sequence_id => 2)
    create(:way_node, :way => way3, :node => node_a, :sequence_id => 1)
    create(:way_node, :way => way3, :node => node_d, :sequence_id => 2)

    get way_path(way1, :xhr => true)
    assert_response :success
    assert_dom "ul:has(> li a[href='#{node_path node_a}']):has(> li a[href='#{node_path node_b}'])", :count => 1 do
      assert_dom "> li", :count => 2 do |list_items|
        assert_dom list_items[0], "a[href='#{node_path node_a}']"
        assert_dom list_items[1], "a[href='#{node_path node_b}']"
        assert_dom list_items[1], "ul", :count => 0
        assert_dom list_items[0], "ul", :count => 1 do
          assert_dom "> li", :count => 2 do |sub_list_items|
            assert_dom sub_list_items[0], "a[href='#{way_path way2}']"
            assert_dom sub_list_items[1], "a[href='#{way_path way3}']"
          end
        end
      end
    end
  end
end
