# frozen_string_literal: true

module ModerationZonesHelper
  def options_for_moderation_zone_period(moderation_zone)
    options = ModerationZone::PERIODS.collect do |h|
      [block_duration_in_words(h.hours), h.to_s]
    end

    options.unshift([t(".period.options.revoke"), 0]) if moderation_zone.persisted?

    options
  end

  def selected_option_for_moderation_zone_period(moderation_zone)
    param_value = params.dig(:moderation_zone, :period)
    value_to_compare =
      if param_value
        param_value.to_i
      elsif moderation_zone.ends_at
        ((moderation_zone.ends_at - Time.now.utc) / 1.hour).ceil
      end

    if value_to_compare
      ModerationZone::PERIODS.min_by do |h|
        (value_to_compare - h).abs
      end
    end
  end

  def moderation_zone_form_ends_at(moderation_zone)
    moderation_zone.ends_at&.beginning_of_minute
  end

  # No lower bound once a zone has already ended: editing it (eg: fixing a
  # typo) shouldn't be blocked just because its expiry is in the past.
  # Otherwise, don't allow picking a time before now.
  def moderation_zone_ends_at_min(moderation_zone)
    return if moderation_zone.persisted? && !moderation_zone.active?

    Time.now.utc.beginning_of_minute
  end

  def moderation_zone_ends_at_max
    10.years.from_now.beginning_of_minute
  end

  def selected_moderation_zone_expiry_type(moderation_zone)
    param_value = params.dig(:moderation_zone, :expiry_type)
    return param_value if %w[relative absolute].include?(param_value)

    moderation_zone.persisted? ? "absolute" : "relative"
  end

  def moderation_zone_short_status(moderation_zone)
    if moderation_zone.active?
      t("moderation_zones.helper.short.active")
    elsif moderation_zone.revoker_id
      t(
        "moderation_zones.helper.short.revoked_html",
        :name => link_to(
          moderation_zone.revoker.display_name,
          moderation_zone.revoker,
          :class => "username d-inline-block text-truncate text-wrap align-bottom",
          :dir => "auto"
        )
      )
    else
      t("moderation_zones.helper.short.ended")
    end
  end
end
