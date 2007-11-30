module TraceHelper
  def link_to_tag(tag)
    if @action == "mine"
      return link_to(tag, :tag => tag, :page => nil)
    else
      return link_to(tag, :tag => tag, :display_name => @display_name, :page => nil)
    end
  end

  def link_to_page(page)
    if @action == "mine"
      return link_to(page, :tag => @tag, :page => page)
    else
      return link_to(page, :tag => @tag, :display_name => @display_name, :page => page)
    end
  end
end
