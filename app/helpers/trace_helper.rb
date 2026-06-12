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

  # Options for the visibility dropdown. Keeps an old value in the list so
  # editing the trace does not change it by mistake.
  def trace_visibility_options(trace)
    visibilities = Trace::VISIBILITIES.dup
    # If the trace still has an old visibility (private or public), add it so it stays selected.
    visibilities.unshift(trace.visibility) if Trace.legacy_visibility?(trace.visibility)
    visibilities.map do |visibility|
      [t("traces.visibility.#{visibility}"), visibility]
    end
  end
end
