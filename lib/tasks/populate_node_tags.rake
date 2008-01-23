namespace 'db' do
  desc 'Populate the node_tags table'
  task :node_tags  do
    require File.dirname(__FILE__) + '/../../config/environment'

    node_count = Node.count
    limit = 1000 #the number of nodes to grab in one go
    offset = 0   

    while offset < node_count
        Node.find(:all, :limit => limit, :offset => offset).each do |node|
        seq_id = 1
        node.tags.split(';').each do |tag|
          nt = NodeTag.new
          nt.id = node.id
          nt.k = tag.split('=')[0]
          nt.v = tag.split('=')[1]
          nt.sequence_id = seq_id 
          nt.save! || raise
          seq_id += 1
        end

        version = 1 #version refers to one set of histories
        node.old_nodes.find(:all, :order => 'timestamp asc').each do |old_node|
        sequence_id = 1 #sequence_id refers to the sequence of node tags within a history
        old_node.tags.split(';').each do |tag|
          ont = OldNodeTag.new
          ont.id = node.id #the id of the node tag
          ont.k = tag.split('=')[0]
          ont.v = tag.split('=')[1]
          ont.version = version
          ont.sequence_id = sequence_id
          ont.save! || raise
          sequence_id += 1
          end     
        version += 1
        end
      end
    offset += limit
    end
  end
end
