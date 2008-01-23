namespace 'db' do
  desc 'Populate the node_tags table'
  task :node_version  do
    require File.dirname(__FILE__) + '/../../config/environment'

    lower_bound = 0
    increment = 100
    node_count = OldNode.count
    puts node_count
    
    while lower_bound < node_count
    upper_bound = lower_bound + increment
    hash = {}

      OldNode.find(:all, :conditions => ['id >= ? AND id < ?',lower_bound, upper_bound], :order => 'timestamp').each do |node|
         hash[node.id] = [] if hash[node.id].nil?
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
          temp_old_node.version = node.version
          temp_old_node.save! || raise
          n +=1 
        end
      end
      lower_bound += increment
    end
  end
end






