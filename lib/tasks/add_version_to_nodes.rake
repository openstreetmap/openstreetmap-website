namespace "db" do
  desc "Adds a version number to the nodes table"
  task :node_version  do
    require File.dirname(__FILE__) + "/../../config/environment"

    increment = 1000
    offset = 0
    id_max = OldNode.find(:first, :order => "id desc").id

    while offset < (id_max + increment)
      hash = {}

      # should be offsetting not selecting
      OldNode.find(:all, :limit => increment, :offset => offset, :order => "timestamp").each do |node|
        hash[node.id] ||= []
        hash[node.id] << node
      end

      hash.each_value do |node_array|
        n = 1
        node_array.each do |node|
          temp_old_node = TempOldNode.new
          temp_old_node.id = node.id
          temp_old_node.latitude = node.latitude
          temp_old_node.longitude = node.longitude
          temp_old_node.user_id = node.user_id
          temp_old_node.visible = node.visible
          temp_old_node.timestamp = node.timestamp
          temp_old_node.tile = node.tile
          temp_old_node.version = n
          temp_old_node.save! || fail
          n += 1
        end
      end
      offset += increment
    end
  end
end
