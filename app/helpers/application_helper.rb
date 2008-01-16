module ApplicationHelper
  def htmlize(text)
    return sanitize(auto_link(simple_format(text), :urls))
  end
end
