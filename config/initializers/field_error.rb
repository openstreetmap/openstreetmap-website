ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  class_attr_index = html_tag.index 'class="'

  if class_attr_index
    html_tag.insert class_attr_index + 7, "field_with_errors "
  else
    html_tag.insert html_tag.index(%r{/?>}), ' class="field_with_errors"'
  end
end
