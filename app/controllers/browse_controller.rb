class BrowseController < ApplicationController
  before_filter :authorize_web  
  layout 'site'
  def way_view 
    begin
      way = Way.find(params[:id])
     
      @way = way
      @name = @way.tags['name'].to_s 
      if @name.length == 0:
	@name = "#" + @way.id.to_s
      end	
      @title = 'Way | ' + (@name)
      
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
  def node_view 
    begin
      node = Node.find(params[:id])
     
      @node = node
      @name = @node.tags_as_hash['name'].to_s 
      if @name.length == 0:
	@name = "#" + @node.id.to_s
      end	
      @title = 'Node | ' + (@name)
      
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
end
