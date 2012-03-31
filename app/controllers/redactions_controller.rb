class RedactionsController < ApplicationController
  layout 'site'
  
  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :require_moderator, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :lookup_redaction, :only => [:show, :edit, :update, :destroy]
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:create, :update, :destroy]

  def index
    @redactions_pages, @redactions = paginate(:redactions, :order => :id, :per_page => 10)
  end

  def new
    @redaction = Redaction.new
  end
     
  def create
    @redaction = Redaction.new
    @redaction.user_id = @user.id
    @redaction.title = params[:redaction][:title]
    @redaction.description = params[:redaction][:description]
    # didn't see this come in from the form - maybe i'm doing something
    # wrong, or markdown is the only thing supported at the moment?
    @redaction.description_format = 'markdown'

    if @redaction.save
      flash[:notice] = t('redaction.create.flash')
      redirect_to @redaction
    else
      render :action => 'new'
    end
  end
     
  def show
  end
  
  def edit
  end
     
  def update
    # note - don't update the user ID
    
    if params[:redaction][:title] and params[:redaction][:title] != @redaction.title
      @redaction.title = params[:redaction][:title]
    end

    if params[:redaction][:description] and params[:redaction][:description] != @redaction.description
      @redaction.description = params[:redaction][:description]
    end

    if @redaction.save
      flash[:notice] = t('redaction.update.flash')
      redirect_to @redaction
    else
      render :action => 'edit'
    end
  end
     
  def destroy
    unless @redaction.old_nodes.empty? and
        @redaction.old_ways.empty? and
        @redaction.old_relations.empty?
      flash[:error] = t('redaction.destroy.not_empty')
      redirect_to @redaction
    else
      if @redaction.destroy
        flash[:notice] = t('redaction.destroy.flash')
        redirect_to :index
      else
        flash[:error] = t('redaction.destroy.error')
        redirect_to @redaction
      end
    end
  end

  private

  def lookup_redaction
    @redaction = Redaction.find(params[:id])
  end
end
