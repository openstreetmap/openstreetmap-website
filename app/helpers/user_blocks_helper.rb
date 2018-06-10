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
      I18n.t("user_blocks.helper.time_past", :time => friendly_date(last_time)).html_safe
    end
  end
end
