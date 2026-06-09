# frozen_string_literal: true

class ModerationZonesController < ApplicationController
  layout :site_layout

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :check_database_writable, :except => [:index, :show]
  before_action :set_moderation_zone, :only => [:show, :edit, :update]

  def index
    @moderation_zones = ModerationZone.all
  end

  def show; end

  def new
    @moderation_zone = ModerationZone.new
  end

  def edit; end

  def create
    @moderation_zone = ModerationZone.new(moderation_zone_params)
    @moderation_zone.creator = current_user

    if @moderation_zone.save
      redirect_to moderation_zones_url, :notice => t(".success")
    else
      render :new, :status => :unprocessable_content
    end
  end

  def update
    check_revocation(@moderation_zone, moderation_zone_params)

    if @moderation_zone.update(moderation_zone_params)
      redirect_to moderation_zones_url, :notice => t(".success"), :status => :see_other
    else
      render :edit, :status => :unprocessable_content
    end
  end

  private

  def set_moderation_zone
    @moderation_zone = ModerationZone.find(params.expect(:id))
  end

  def moderation_zone_params
    params.expect(:moderation_zone => [:name, :reason, :zone, :period]).tap do |safe_params|
      safe_params[:ends_at] = safe_params.delete("period").to_i.hours.from_now
    end
  end

  def check_revocation(modzone, modzone_params)
    duplicate = modzone.dup
    previously_active = duplicate.active?
    duplicate.assign_attributes(modzone_params)
    modzone.revoker = current_user if previously_active && !duplicate.active?
  end
end
