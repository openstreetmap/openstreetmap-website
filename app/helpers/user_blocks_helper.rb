module UserBlocksHelper
  ##
  # returns a translated string representing the status of the
  # user block (i.e: whether it's active, what the expiry time is)
  def block_status(block)
    if block.active?
      if block.needs_view?
        I18n.t("user_block.helper.until_login")
      else
        I18n.t("user_block.helper.time_future", :time => distance_of_time_in_words_to_now(block.ends_at))
      end
    else
      # the max of the last update time or the ends_at time is when this block finished
      # either because the user viewed the block (updated_at) or it expired or was
      # revoked (ends_at)
      last_time = [block.ends_at, block.updated_at].max
      I18n.t("user_block.helper.time_past", :time => distance_of_time_in_words_to_now(last_time))
    end
  end
end
