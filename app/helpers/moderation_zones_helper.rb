# frozen_string_literal: true

module ModerationZonesHelper
  def options_for_moderation_zone_period
    ModerationZone::PERIODS.collect do |h|
      [block_duration_in_words(h.hours), h.to_s]
    end
  end

  def selected_option_for_moderation_zone_period(moderation_zone)
    param_value = params.dig(:moderation_zone, :period)
    if param_value
      ModerationZone::PERIODS.min_by do |h|
        (param_value.to_i - h).abs
      end
    elsif moderation_zone.ends_at
      value_to_compare = ((moderation_zone.ends_at - Time.now.utc) / 1.hour).ceil.to_s
      ModerationZone::PERIODS.min_by do |h|
        (value_to_compare.to_i - h).abs
      end
    end
  end
end
