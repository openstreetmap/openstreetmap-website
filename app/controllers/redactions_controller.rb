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
    @redactions = Redaction.order(:id)
  end

  def new
    @redaction = Redaction.new
  end

  def create
    @redaction = Redaction.new
    @redaction.user = @user
    @redaction.title = params[:redaction][:title]
    @redaction.description = params[:redaction][:description]
    # note that the description format will default to 'markdown'

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
    @redaction.title = params[:redaction][:title]
    @redaction.description = params[:redaction][:description]

    if @redaction.save
      flash[:notice] = t('redaction.update.flash')
      redirect_to @redaction
    else
      render :action => 'edit'
    end
  end

  def destroy
    unless @redaction.old_nodes.empty? &&
           @redaction.old_ways.empty? &&
           @redaction.old_relations.empty?
      flash[:error] = t('redaction.destroy.not_empty')
      redirect_to @redaction
    else
      if @redaction.destroy
        flash[:notice] = t('redaction.destroy.flash')
        redirect_to :redactions
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
