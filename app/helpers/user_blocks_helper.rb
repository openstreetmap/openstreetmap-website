module UserBlocksHelper
  include ActionView::Helpers::TranslationHelper

  ##
  # returns a translated string representing the status of the
  # user block (i.e: whether it's active, what the expiry time is)
  def block_status(block)
    if block.active?
      # if the block hasn't expired yet show the date, if the user just needs to login show that
      if block.needs_view?
        if block.ends_at > Time.now.utc
          t("user_blocks.helper.time_future_and_until_login_html", :time => friendly_date(block.ends_at))
        else
          t("user_blocks.helper.until_login")
        end
      else
        t("user_blocks.helper.time_future_html", :time => friendly_date(block.ends_at))
      end
    else
      # the max of the last update time or the ends_at time is when this block finished
      # either because the user viewed the block (updated_at) or it expired or was
      # revoked (ends_at)
      last_time = block.deactivates_at || [block.ends_at, block.updated_at].max
      t("user_blocks.helper.time_past_html", :time => friendly_date_ago(last_time))
    end
  end

  def block_short_status(block)
    if block.active?
      if block.ends_at > Time.now.utc
        t("user_blocks.helper.short.active")
      else
        t("user_blocks.helper.short.active_until_read")
      end
    else
      if block.revoker_id.nil?
        if block.deactivates_at > block.ends_at
          t("user_blocks.helper.short.read_html", :time => block_short_time_in_past(block.deactivates_at))
        else
          t("user_blocks.helper.short.ended")
        end
      else
        t("user_blocks.helper.short.revoked_html", :name => link_to(block.revoker.display_name, block.revoker,
                                                                    :class => "username d-inline-block text-truncate text-wrap align-bottom",
                                                                    :dir => "auto"))
      end
    end
  end

  def block_short_time_in_future(time)
    tag.time l(time.to_date),
             :datetime => time.xmlschema,
             :title => t("user_blocks.helper.short.time_in_future_title",
                         :time_absolute => l(time, :format => :friendly),
                         :time_relative => time_ago_in_words(time))
  end

  def block_short_time_in_past(time)
    tag.time l(time.to_date),
             :datetime => time.xmlschema,
             :title => t("user_blocks.helper.short.time_in_past_title",
                         :time_absolute => l(time, :format => :friendly),
                         :time_relative => time_ago_in_words(time, :scope => :"datetime.distance_in_words_ago"))
  end

  def block_duration_in_words(duration)
    # Ensure the requested duration isn't negative, even by a millisecond
    duration = 0 if duration.negative?
    parts = ActiveSupport::Duration.build(duration).parts
    if duration < 1.day
      t("user_blocks.helper.block_duration.hours", :count => parts.fetch(:hours, 0))
    elsif duration < 1.week
      t("user_blocks.helper.block_duration.days", :count => parts[:days])
    elsif duration < 1.month
      t("user_blocks.helper.block_duration.weeks", :count => parts[:weeks])
    elsif duration < 1.year
      t("user_blocks.helper.block_duration.months", :count => parts[:months])
    else
      t("user_blocks.helper.block_duration.years", :count => parts[:years])
    end
  end
end
