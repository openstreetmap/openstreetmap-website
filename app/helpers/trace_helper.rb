# frozen_string_literal: true

module TraceHelper
  def trace_image(trace, animated: false, only_path: true, **options)
    args = [trace.user, trace, { :only_path => only_path }]
    src = animated ? trace_picture_url(*args) : trace_icon_url(*args)
    image_tag(src, { :class => "trace_image", :alt => "" }.merge(options))
  end

  def link_to_tag(tag)
    link_to(tag, :tag => tag, :page => nil)
  end

  def trace_icon(trace, options = {})
    trace_image(trace, :size => 50, **options)
  end

  def trace_picture(trace, options = {})
    trace_image(trace, :animated => true, :size => 250, **options)
  end
end
