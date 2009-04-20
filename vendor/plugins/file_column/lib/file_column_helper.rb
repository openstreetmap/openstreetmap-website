# This module contains helper methods for displaying and uploading files
# for attributes created by +FileColumn+'s +file_column+ method. It will be
# automatically included into ActionView::Base, thereby making this module's
# methods available in all your views.
module FileColumnHelper
  
  # Use this helper to create an upload field for a file_column attribute. This will generate
  # an additional hidden field to keep uploaded files during form-redisplays. For example,
  # when called with
  #
  #   <%= file_column_field("entry", "image") %>
  #
  # the following HTML will be generated (assuming the form is redisplayed and something has
  # already been uploaded):
  #
  #   <input type="hidden" name="entry[image_temp]" value="..." />
  #   <input type="file" name="entry[image]" />
  #
  # You can use the +option+ argument to pass additional options to the file-field tag.
  #
  # Be sure to set the enclosing form's encoding to 'multipart/form-data', by
  # using something like this:
  #
  #    <%= form_tag {:action => "create", ...}, :multipart => true %>
  def file_column_field(object, method, options={})
    result = ActionView::Helpers::InstanceTag.new(object.dup, method.to_s+"_temp", self).to_input_field_tag("hidden", {})
    result << ActionView::Helpers::InstanceTag.new(object.dup, method, self).to_input_field_tag("file", options)
  end
  
  # Creates an URL where an uploaded file can be accessed. When called for an Entry object with
  # id 42 (stored in <tt>@entry</tt>) like this
  #
  #   <%= url_for_file_column(@entry, "image")
  #
  # the following URL will be produced, assuming the file "test.png" has been stored in
  # the "image"-column of an Entry object stored in <tt>@entry</tt>:
  #
  #  /entry/image/42/test.png
  #
  # This will produce a valid URL even for temporary uploaded files, e.g. files where the object
  # they are belonging to has not been saved in the database yet.
  #
  # The URL produces, although starting with a slash, will be relative
  # to your app's root. If you pass it to one rails' +image_tag+
  # helper, rails will properly convert it to an absolute
  # URL. However, this will not be the case, if you create a link with
  # the +link_to+ helper. In this case, you can pass <tt>:absolute =>
  # true</tt> to +options+, which will make sure, the generated URL is
  # absolute on your server.  Examples:
  #
  #    <%= image_tag url_for_file_column(@entry, "image") %>
  #    <%= link_to "Download", url_for_file_column(@entry, "image", :absolute => true) %>
  #
  # If there is currently no uploaded file stored in the object's column this method will
  # return +nil+.
  def url_for_file_column(object, method, options=nil)
    case object
    when String, Symbol
      object = instance_variable_get("@#{object.to_s}")
    end

    # parse options
    subdir = nil
    absolute = false
    if options
      case options
      when Hash
        subdir = options[:subdir]
        absolute = options[:absolute]
      when String, Symbol
        subdir = options
      end
    end
    
    relative_path = object.send("#{method}_relative_path", subdir)
    return nil unless relative_path

    url = ""
    url << request.relative_url_root.to_s if absolute
    url << "/"
    url << object.send("#{method}_options")[:base_url] << "/"
    url << relative_path
  end

  # Same as +url_for_file_colum+ but allows you to access different versions
  # of the image that have been processed by RMagick.
  #
  # If your +options+ parameter is non-nil this will
  # access a different version of an image that will be produced by
  # RMagick. You can use the following types for +options+:
  #
  # * a <tt>:symbol</tt> will select a version defined in the model
  #   via FileColumn::Magick's <tt>:versions</tt> feature.
  # * a <tt>geometry_string</tt> will dynamically create an
  #   image resized as specified by <tt>geometry_string</tt>. The image will
  #   be stored so that it does not have to be recomputed the next time the
  #   same version string is used.
  # * <tt>some_hash</tt> will dynamically create an image
  #   that is created according to the options in <tt>some_hash</tt>. This
  #   accepts exactly the same options as Magick's version feature.
  #
  # The version produced by RMagick will be stored in a special sub-directory.
  # The directory's name will be derived from the options you specified
  # (via a hash function) but if you want
  # to set it yourself, you can use the <tt>:name => name</tt> option.
  #
  # Examples:
  #
  #    <%= url_for_image_column @entry, "image", "640x480" %>
  #
  # will produce an URL like this
  #
  #    /entry/image/42/bdn19n/filename.jpg
  #    # "640x480".hash.abs.to_s(36) == "bdn19n"
  #
  # and
  #
  #    <%= url_for_image_column @entry, "image", 
  #       :size => "50x50", :crop => "1:1", :name => "thumb" %>
  #
  # will produce something like this:
  #
  #    /entry/image/42/thumb/filename.jpg
  #
  # Hint: If you are using the same geometry string / options hash multiple times, you should
  # define it in a helper to stay with DRY. Another option is to define it in the model via
  # FileColumn::Magick's <tt>:versions</tt> feature and then refer to it via a symbol.
  #
  # The URL produced by this method is relative to your application's root URL,
  # although it will start with a slash.
  # If you pass this URL to rails' +image_tag+ helper, it will be converted to an
  # absolute URL automatically.
  # If there is currently no image uploaded, or there is a problem while loading
  # the image this method will return +nil+.
  def url_for_image_column(object, method, options=nil)
    case object
    when String, Symbol
      object = instance_variable_get("@#{object.to_s}")
    end
    subdir = nil
    if options
      subdir = object.send("#{method}_state").create_magick_version_if_needed(options)
    end
    if subdir.nil?
      nil
    else
      url_for_file_column(object, method, subdir)
    end
  end
end
