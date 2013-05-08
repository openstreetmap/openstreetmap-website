class BrowseController < ApplicationController
  layout 'site', :except => [ :start ]

  before_filter :authorize_web  
  before_filter :set_locale 
  before_filter { |c| c.check_database_readable(true) }
  around_filter :web_timeout, :except => [:start]

  def start 
  end
  
  def relation
    @type = "relation"
    @relation = Relation.find(params[:id])
    @next = Relation.visible.where("id > ?", @relation.id).order("id ASC").first
    @prev = Relation.visible.where("id < ?", @relation.id).order("id DESC").first
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
    @next = Way.visible.where("id > ?", @way.id).order("id ASC").first
    @prev = Way.visible.where("id < ?", @way.id).order("id DESC").first
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
    @next = Node.visible.where("id > ?", @node.id).order("id ASC").first
    @prev = Node.visible.where("id < ?", @node.id).order("id DESC").first
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
    @next = Changeset.where("id > ?", @changeset.id).order("id ASC").first
    @prev = Changeset.where("id < ?", @changeset.id).order("id DESC").first

    if @changeset.user.data_public?
      @next_by_user = Changeset.where("user_id = ? AND id > ?", @changeset.user_id, @changeset.id).order("id ASC").first
      @prev_by_user = Changeset.where("user_id = ? AND id < ?", @changeset.user_id, @changeset.id).order("id DESC").first
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def note
    @type = "note"
    @note = Note.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @note.visible?
    @next = Note.find(:first, :order => "id ASC", :conditions => [ "status != 'hidden' AND id > :id", { :id => @note.id }] )
    @prev = Note.find(:first, :order => "id DESC", :conditions => [ "status != 'hidden' AND id < :id", { :id => @note.id }] )
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
