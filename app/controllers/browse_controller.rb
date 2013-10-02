class BrowseController < ApplicationController
  layout :map_layout

  before_filter :authorize_web  
  before_filter :set_locale 
  before_filter { |c| c.check_database_readable(true) }
  around_filter :web_timeout, :except => [:start]

  def start
    render :layout => false
  end

  def relation
    @type = "relation"
    @relation = Relation.find(params[:id])
    @next = Relation.visible.where("id > ?", @relation.id).order(:id => :asc).first
    @prev = Relation.visible.where("id < ?", @relation.id).order(:id => :desc).first
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
    @way = Way.preload(:way_tags, :containing_relation_members, :changeset => :user, :nodes => [:node_tags, :ways => :way_tags]).find(params[:id])
    @next = Way.visible.where("id > ?", @way.id).order(:id => :asc).first
    @prev = Way.visible.where("id < ?", @way.id).order(:id => :desc).first
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
  
  def way_history
    @type = "way"
    @way = Way.preload(:way_tags, :old_ways => { :changeset => :user }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def node
    @type = "node"
    @node = Node.find(params[:id])
    @next = Node.visible.where("id > ?", @node.id).order(:id => :asc).first
    @prev = Node.visible.where("id < ?", @node.id).order(:id => :desc).first
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
    @next = Changeset.where("id > ?", @changeset.id).order(:id => :asc).first
    @prev = Changeset.where("id < ?", @changeset.id).order(:id => :desc).first

    if @changeset.user.data_public?
      @next_by_user = @changeset.user.changesets.where("id > ?", @changeset.id).order(:id => :asc).first
      @prev_by_user = @changeset.user.changesets.where("id < ?", @changeset.id).order(:id => :desc).first
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def note
    @type = "note"
    @note = Note.find(params[:id])
    @title = "#{I18n.t('browse.note.title')} | #{@note.id}"
    @next = Note.visible.where("id > ?", @note.id).order(:id => :asc).first
    @prev = Note.visible.where("id < ?", @note.id).order(:id => :desc).first
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
