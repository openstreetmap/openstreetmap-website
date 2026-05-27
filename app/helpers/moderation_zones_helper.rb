# frozen_string_literal: true

module ModerationZonesHelper
  def options_for_moderation_zone_period
    ModerationZone::PERIODS.collect do |h|
      [block_duration_in_words(h.hours), h.to_s]
    end
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
end
