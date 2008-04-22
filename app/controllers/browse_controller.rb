class BrowseController < ApplicationController
  before_filter :authorize_web  
  layout 'site'

  def start 
    @nodes = Node.find(:all, :order => "timestamp DESC", :limit=> 20)  
  end
  def index
    @nodes = Node.find(:all, :order => "timestamp DESC", :limit=> 20)  
  end
  
  def relation 
    begin
      @relation = Relation.find(params[:id])
     
      @name = @relation.tags['name'].to_s 
      if @name.length == 0:
	@name = "#" + @relation.id.to_s
      end
	
      @title = 'Relation | ' + (@name)
      @next = Relation.find(:first, :order => "id ASC", :conditions => [ "visible = true AND id > :id", { :id => @relation.id }] ) 
      @prev = Relation.find(:first, :order => "id DESC", :conditions => [ "visible = true AND id < :id", { :id => @relation.id }] ) 
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
  
  def relation_history
    begin
      @relation = Relation.find(params[:id])
     
      @name = @relation.tags['name'].to_s 
      if @name.length == 0:
	@name = "#" + @relation.id.to_s
      end
	
      @title = 'Relation History | ' + (@name)
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
  
  def way 
    begin
      @way = Way.find(params[:id])
     
      @name = @way.tags['name'].to_s 
      if @name.length == 0:
	@name = "#" + @way.id.to_s
      end
	
      @title = 'Way | ' + (@name)
      @next = Way.find(:first, :order => "id ASC", :conditions => [ "visible = true AND id > :id", { :id => @way.id }] ) 
      @prev = Way.find(:first, :order => "id DESC", :conditions => [ "visible = true AND id < :id", { :id => @way.id }] ) 
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
  
  def way_history 
    begin
      @way = Way.find(params[:id])
     
      @name = @way.tags['name'].to_s 
      if @name.length == 0:
	@name = "#" + @way.id.to_s
      end
	
      @title = 'Way History | ' + (@name)
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end

  def node 
    begin
      @node = Node.find(params[:id])
     
      @name = @node.tags_as_hash['name'].to_s 
      if @name.length == 0:
	@name = "#" + @node.id.to_s
      end
	
      @title = 'Node | ' + (@name)
      @next = Node.find(:first, :order => "id ASC", :conditions => [ "visible = true AND id > :id", { :id => @node.id }] ) 
      @prev = Node.find(:first, :order => "id DESC", :conditions => [ "visible = true AND id < :id", { :id => @node.id }] ) 
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
  
  def node_history 
    begin
      @node = Node.find(params[:id])
     
      @name = @node.tags_as_hash['name'].to_s 
      if @name.length == 0:
	@name = "#" + @node.id.to_s
      end
	
      @title = 'Node History | ' + (@name)
    rescue ActiveRecord::RecordNotFound
      render :nothing => true, :status => :not_found
    end
  end
end
