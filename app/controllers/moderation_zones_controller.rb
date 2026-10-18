# frozen_string_literal: true

class ModerationZonesController < ApplicationController
  layout :site_layout

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :check_database_readable
  before_action :check_database_writable, :except => [:index]
  before_action :set_moderation_zone, :only => [:edit, :update]

  def index
    @moderation_zones = ModerationZone.preload(:creator, :revoker).all
  end

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

    if cannot?(:update, @moderation_zone)
      flash[:error] = @moderation_zone.revoker ? t(".only_creator_or_revoker_can_edit") : t(".only_creator_can_edit")
      redirect_to moderation_zones_url
    elsif current_user != @moderation_zone.creator && updating_without_revoking?(@moderation_zone, moderation_zone_params)
      flash[:error] = t(".only_creator_can_edit_without_revoking")
      redirect_to moderation_zones_url
    elsif reactivating?(@moderation_zone, moderation_zone_params)
      flash[:error] = t(".no_reactivation")
      redirect_to moderation_zones_url
    elsif @moderation_zone.update(moderation_zone_params)
      redirect_to moderation_zones_url, :notice => t(".success"), :status => :see_other
    else
      render :edit, :status => :unprocessable_content
    end
  end

  private

  def set_moderation_zone
    @moderation_zone = ModerationZone.preload(:creator, :revoker).find(params.expect(:id))
  end

  def moderation_zone_params
    params.expect(:moderation_zone => [:name, :reason, :zone, :period, :expiry_type, :ends_at]).tap do |safe_params|
      expiry_type = safe_params.delete(:expiry_type)
      raise RailsParam::InvalidParameterError, "expiry_type is invalid" unless %w[relative absolute].include?(expiry_type)

      period = safe_params.delete(:period)

      safe_params[:ends_at] = if expiry_type == "absolute"
                                normalized_absolute_ends_at(safe_params[:ends_at])
                              else
                                period.to_i.hours.from_now
                              end
    end
  end

  def normalized_absolute_ends_at(ends_at_param)
    return if ends_at_param.blank?

    ends_at = Time.zone.parse(ends_at_param.to_s)&.utc
    return unless ends_at

    ends_at = ModerationZone.round_to_closest_minute(ends_at)
    ends_at = ModerationZone.round_to_next_minute(Time.now.utc) if ends_at.past? && extending_active_period?
    ends_at
  end

  # True when the submitted expiry must not be allowed to land in the past:
  # either we're creating a new record, or we're extending one that is
  # currently active (and so must remain active).
  def extending_active_period?
    action_name == "create" || @moderation_zone&.active?
  end

  def check_revocation(original, changes)
    original.revoker = current_user if original.active? && !projected_record(original, changes).active?
  end

  def updating_without_revoking?(original, changes)
    original.active? && projected_record(original, changes).active?
  end

  def reactivating?(original, changes)
    !original.active? && projected_record(original, changes).active?
  end

  def projected_record(original, changes)
    original.dup.tap do |duplicate|
      duplicate.assign_attributes(changes)
    end
  end
end
