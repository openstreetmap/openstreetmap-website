# frozen_string_literal: true

module HeatmapHelper
  def prepare_heatmap(data, from, to)
    # Pad the start by one week to ensure the heatmap can start on the first day of the week
    all_days = ((from - 1.week).to_date..to.to_date).map do |date|
      data[date] || { :date => date, :total_changes => 0 }
    end

    # Get unique months with repeating months and count into the next year with numbers over 12
    month_offset = 0
    months = ((from - 2.weeks).to_date..(to + 1.week).to_date)
             .map(&:month)
             .chunk_while { |before, after| before == after }
             .map(&:first)
             .map do |month|
               month_offset += 12 if month == 1
               month + month_offset
             end

    {
      :days => all_days,
      :months => months,
      :max_per_day => data.values.pluck(:total_changes).max
    }
  end
end
