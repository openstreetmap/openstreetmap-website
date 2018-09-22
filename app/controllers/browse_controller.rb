class BrowseController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action(:except => [:query]) { |c| c.check_database_readable(true) }
  before_action :require_oauth
  around_action :web_timeout

  def relation
    @type = "relation"
    @feature = Relation.preload(:relation_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :relation_members => :member).find(params[:id])
    render "feature"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def relation_history
    @type = "relation"
    @feature = Relation.preload(:relation_tags, :old_relations => [:old_tags, :changeset => [:changeset_tags, :user], :old_members => :member]).find(params[:id])
    render "history"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def way
    @type = "way"
    @feature = Way.preload(:way_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :nodes => [:node_tags, :ways => :way_tags]).find(params[:id])
    render "feature"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def way_history
    @type = "way"
    @feature = Way.preload(:way_tags, :old_ways => [:old_tags, :changeset => [:changeset_tags, :user], :old_nodes => { :node => [:node_tags, :ways] }]).find(params[:id])
    render "history"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def node
    @type = "node"
    @feature = Node.preload(:node_tags, :containing_relation_members, :changeset => [:changeset_tags, :user], :ways => :way_tags).find(params[:id])
    render "feature"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def node_history
    @type = "node"
    @feature = Node.preload(:node_tags, :old_nodes => [:old_tags, :changeset => [:changeset_tags, :user]]).find(params[:id])
    render "history"
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def changeset
    @type = "changeset"
    @changeset = Changeset.find(params[:id])
    @comments = if current_user&.moderator?
                  @changeset.comments.unscope(:where => :visible).includes(:author)
                else
                  @changeset.comments.includes(:author)
                end
    @node_pages, @nodes = paginate(:old_nodes, :conditions => { :changeset_id => @changeset.id }, :per_page => 20, :parameter => "node_page")
    @way_pages, @ways = paginate(:old_ways, :conditions => { :changeset_id => @changeset.id }, :per_page => 20, :parameter => "way_page")
    @relation_pages, @relations = paginate(:old_relations, :conditions => { :changeset_id => @changeset.id }, :per_page => 20, :parameter => "relation_page")
    if @changeset.user.data_public?
      @next_by_user = @changeset.user.changesets.where("id > ?", @changeset.id).reorder(:id => :asc).first
      @prev_by_user = @changeset.user.changesets.where("id < ?", @changeset.id).reorder(:id => :desc).first
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end

  def note
    @type = "note"

    if current_user&.moderator?
      @note = Note.find(params[:id])
      @note_comments = @note.comments.unscope(:where => :visible)
    else
      @note = Note.visible.find(params[:id])
      @note_comments = @note.comments
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "not_found", :status => :not_found
  end
end
