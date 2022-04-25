module TraceHelper
  def link_to_tag(tag)
    link_to(tag, :tag => tag, :page => nil)
  end
end
