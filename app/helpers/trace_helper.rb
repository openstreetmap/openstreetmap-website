module TraceHelper
  def link_to_tag(tag)
    if @action == "mine"
      return link_to tag, :tag => tag
    else
      return link_to tag, :tag => tag, :display_name => @display_name
    end
  end
end
