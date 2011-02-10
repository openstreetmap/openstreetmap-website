class BrowseController < ApplicationController
  layout 'site'

  before_filter :authorize_web  
  before_filter :set_locale 
  before_filter { |c| c.check_database_readable(true) }
  around_filter :web_timeout, :except => [:start]

  def start 
  end
  
  def relation
    @type = "relation"
    @relation = Relation.find(params[:id])
    @next = Relation.find(:first, :order => "id ASC", :conditions => [ "visible = true AND id > :id", { :id => @relation.id }] )
    @prev = Relation.find(:first, :order => "id DESC", :conditions => [ "visible = true AND id < :id", { :id => @relation.id }] )
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
  
  def relation_history
    @type = "relation"
    @relation = Relation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
  
  def way
    @type = "way"
    @way = Way.find(params[:id], :include => [:way_tags, {:changeset => :user}, {:nodes => [:node_tags, {:ways => :way_tags}]}, :containing_relation_members])
    @next = Way.find(:first, :order => "id ASC", :conditions => [ "visible = true AND id > :id", { :id => @way.id }] )
    @prev = Way.find(:first, :order => "id DESC", :conditions => [ "visible = true AND id < :id", { :id => @way.id }] )

    # Used for edit link, takes approx middle node of way
    @midnode = @way.nodes[@way.nodes.length/2]
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
  
  def way_history
    @type = "way"
    @way = Way.find(params[:id], :include => [:way_tags, {:old_ways => {:changeset => :user}}])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def node
    @type = "node"
    @node = Node.find(params[:id])
    @next = Node.find(:first, :order => "id ASC", :conditions => [ "visible = true AND id > :id", { :id => @node.id }] )
    @prev = Node.find(:first, :order => "id DESC", :conditions => [ "visible = true AND id < :id", { :id => @node.id }] )
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
  
  def node_history
    @type = "node"
    @node = Node.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
  
  def changeset
    @type = "changeset"

    @changeset = Changeset.find(params[:id])
    @node_pages, @nodes = paginate(:old_nodes, :conditions => {:changeset_id => @changeset.id}, :per_page => 20, :parameter => 'node_page')
    @way_pages, @ways = paginate(:old_ways, :conditions => {:changeset_id => @changeset.id}, :per_page => 20, :parameter => 'way_page')
    @relation_pages, @relations = paginate(:old_relations, :conditions => {:changeset_id => @changeset.id}, :per_page => 20, :parameter => 'relation_page')
      
    @title = "#{I18n.t('browse.changeset.title')} | #{@changeset.id}"
    @next = Changeset.find(:first, :order => "id ASC", :conditions => [ "id > :id", { :id => @changeset.id }] ) 
    @prev = Changeset.find(:first, :order => "id DESC", :conditions => [ "id < :id", { :id => @changeset.id }] )

    if @changeset.user.data_public?
      @next_by_user = Changeset.find(:first, :order => "id ASC", :conditions => [ "id > :id AND user_id = :user_id", { :id => @changeset.id, :user_id => @changeset.user_id }] )
      @prev_by_user = Changeset.find(:first, :order => "id DESC", :conditions => [ "id < :id AND user_id = :user_id", { :id => @changeset.id, :user_id => @changeset.user_id }] )
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
