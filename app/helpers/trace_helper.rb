module TraceHelper
  def link_to_tag(tag)
    if @action == "mine"
      link_to(tag, :tag => tag, :page => nil)
    else
      link_to(tag, :tag => tag, :display_name => @display_name, :page => nil)
    end
  end
end
