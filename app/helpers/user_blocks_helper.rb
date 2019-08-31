module UserBlocksHelper
  ##
  # returns a translated string representing the status of the
  # user block (i.e: whether it's active, what the expiry time is)
  def block_status(block)
    if block.active?
      # if the block hasn't expired yet show the date, if the user just needs to login show that
      if block.needs_view?
        if block.ends_at > Time.now.getutc
          I18n.t("user_blocks.helper.time_future_and_until_login", :time => friendly_date(block.ends_at)).html_safe
        else
          I18n.t("user_blocks.helper.until_login")
        end
      else
        I18n.t("user_blocks.helper.time_future", :time => friendly_date(block.ends_at)).html_safe
      end
    else
      # the max of the last update time or the ends_at time is when this block finished
      # either because the user viewed the block (updated_at) or it expired or was
      # revoked (ends_at)
      last_time = [block.ends_at, block.updated_at].max
      I18n.t("user_blocks.helper.time_past", :time => friendly_date_ago(last_time)).html_safe
    end
  end

  def block_duration_in_words(duration)
    parts = ActiveSupport::Duration.build(duration).parts
    if duration < 1.day
      I18n.t("user_blocks.helper.block_duration.hours", :count => parts[:hours])
    elsif duration < 1.week
      I18n.t("user_blocks.helper.block_duration.days", :count => parts[:days])
    elsif duration < 1.month
      I18n.t("user_blocks.helper.block_duration.weeks", :count => parts[:weeks])
    elsif duration < 1.year
      I18n.t("user_blocks.helper.block_duration.months", :count => parts[:months])
    else
      I18n.t("user_blocks.helper.block_duration.years", :count => parts[:years])
    end
  end
end
