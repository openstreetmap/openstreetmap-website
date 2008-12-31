class BrowseController < ApplicationController
  layout 'site'

  before_filter :authorize_web  
  before_filter { |c| c.check_database_availability(true) }

  def start 
  end
  
  def index
    @changesets = Changeset.find(:all, :order => "closed_at DESC", :conditions => ['closed_at < ?', DateTime.now], :limit=> 20)
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
      @type = "relation"
      render :action => "not_found", :status => :not_found
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
      @type = "relation"
      render :action => "not_found", :status => :not_found
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
      @type = "way"
      render :action => "not_found", :status => :not_found
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
      @type = "way"
      render :action => "not_found", :status => :not_found
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
      @type = "node"
      render :action => "not_found", :status => :not_found
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
      @type = "way"
      render :action => "not_found", :status => :not_found
    end
  end
  
  def changeset
    begin
      @changeset = Changeset.find(params[:id])
      @node_pages, @nodes = paginate(:old_nodes, :conditions => {:changeset_id => @changeset.id}, :per_page => 20, :parameter => 'node_page')
      @way_pages, @ways = paginate(:old_ways, :conditions => {:changeset_id => @changeset.id}, :per_page => 20, :parameter => 'way_page')
      @relation_pages, @relations = paginate(:old_relations, :conditions => {:changeset_id => @changeset.id}, :per_page => 20, :parameter => 'relation_page')
      
      @title = "Changeset | #{@changeset.id}"
      @next = Changeset.find(:first, :order => "id ASC", :conditions => [ "id > :id", { :id => @changeset.id }] ) 
      @prev = Changeset.find(:first, :order => "id DESC", :conditions => [ "id < :id", { :id => @changeset.id }] ) 
    rescue ActiveRecord::RecordNotFound
      @type = "changeset"
      render :action => "not_found", :status => :not_found
    end
  end
end
