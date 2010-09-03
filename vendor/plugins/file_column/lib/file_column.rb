require 'fileutils'
require 'tempfile'
require 'magick_file_column'

module FileColumn # :nodoc:
  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end

  def self.create_state(instance,attr)
    filename = instance[attr]
    if filename.nil? or filename.empty?
      NoUploadedFile.new(instance,attr)
    else
      PermanentUploadedFile.new(instance,attr)
    end
  end

  def self.init_options(defaults, model, attr)
    options = defaults.dup
    options[:store_dir] ||= File.join(options[:root_path], model, attr)
    unless options[:store_dir].is_a?(Symbol)
      options[:tmp_base_dir] ||= File.join(options[:store_dir], "tmp")
    end
    options[:base_url] ||= options[:web_root] + File.join(model, attr)

    [:store_dir, :tmp_base_dir].each do |dir_sym|
      if options[dir_sym].is_a?(String) and !File.exists?(options[dir_sym])
        FileUtils.mkpath(options[dir_sym])
      end
    end

    options
  end

  class BaseUploadedFile # :nodoc:

    def initialize(instance,attr)
      @instance, @attr = instance, attr
      @options_method = "#{attr}_options".to_sym
    end


    def assign(file)
      if file.is_a? File
        # this did not come in via a CGI request. However,
        # assigning files directly may be useful, so we
        # make just this file object similar enough to an uploaded
        # file that we can handle it. 
        file.extend FileColumn::FileCompat
      end

      if file.nil?
        delete
      else
        if file.size == 0
          # user did not submit a file, so we
          # can simply ignore this
          self
        else
          if file.is_a?(String)
            # if file is a non-empty string it is most probably
            # the filename and the user forgot to set the encoding
            # to multipart/form-data. Since we would raise an exception
            # because of the missing "original_filename" method anyways,
            # we raise a more meaningful exception rightaway.
            raise TypeError.new("Do not know how to handle a string with value '#{file}' that was passed to a file_column. Check if the form's encoding has been set to 'multipart/form-data'.")
          end
          upload(file)
        end
      end
    end

    def just_uploaded?
      @just_uploaded
    end

    def on_save(&blk)
      @on_save ||= []
      @on_save << Proc.new
    end
    
    # the following methods are overriden by sub-classes if needed

    def temp_path
      nil
    end

    def absolute_dir
      if absolute_path then File.dirname(absolute_path) else nil end
    end

    def relative_dir
      if relative_path then File.dirname(relative_path) else nil end
    end

    def after_save
      @on_save.each { |blk| blk.call } if @on_save
      self
    end

    def after_destroy
    end

    def options
      @instance.send(@options_method)
    end

    private
    
    def store_dir
      if options[:store_dir].is_a? Symbol
        raise ArgumentError.new("'#{options[:store_dir]}' is not an instance method of class #{@instance.class.name}") unless @instance.respond_to?(options[:store_dir])

        dir = File.join(options[:root_path], @instance.send(options[:store_dir]))
        FileUtils.mkpath(dir) unless File.exists?(dir)
        dir
      else 
        options[:store_dir]
      end
    end

    def tmp_base_dir
      if options[:tmp_base_dir]
        options[:tmp_base_dir] 
      else
        dir = File.join(store_dir, "tmp")
        FileUtils.mkpath(dir) unless File.exists?(dir)
        dir
      end
    end

    def clone_as(klass)
      klass.new(@instance, @attr)
    end

  end
    

  class NoUploadedFile < BaseUploadedFile # :nodoc:
    def delete
      # we do not have a file so deleting is easy
      self
    end

    def upload(file)
      # replace ourselves with a TempUploadedFile
      temp = clone_as TempUploadedFile
      temp.store_upload(file)
      temp
    end

    def absolute_path(subdir=nil)
      nil
    end


    def relative_path(subdir=nil)
      nil
    end

    def assign_temp(temp_path)
      return self if temp_path.nil? or temp_path.empty?
      temp = clone_as TempUploadedFile
      temp.parse_temp_path temp_path
      temp
    end
  end

  class RealUploadedFile < BaseUploadedFile # :nodoc:
    def absolute_path(subdir=nil)
      if subdir
        File.join(@dir, subdir, @filename)
      else
        File.join(@dir, @filename)
      end
    end

    def relative_path(subdir=nil)
      if subdir
        File.join(relative_path_prefix, subdir, @filename)
      else
        File.join(relative_path_prefix, @filename)
      end
    end

    private

    # regular expressions to try for identifying extensions
    EXT_REGEXPS = [ 
      /^(.+)\.([^.]+\.[^.]+)$/, # matches "something.tar.gz"
      /^(.+)\.([^.]+)$/ # matches "something.jpg"
    ]

    def split_extension(filename,fallback=nil)
      EXT_REGEXPS.each do |regexp|
        if filename =~ regexp
          base,ext = $1, $2
          return [base, ext] if options[:extensions].include?(ext.downcase)
        end
      end
      if fallback and filename =~ EXT_REGEXPS.last
        return [$1, $2]
      end
      [filename, ""]
    end
    
  end

  class TempUploadedFile < RealUploadedFile # :nodoc:

    def store_upload(file)
      @tmp_dir = FileColumn.generate_temp_name
      @dir = File.join(tmp_base_dir, @tmp_dir)      
      FileUtils.mkdir(@dir)
      
      @filename = FileColumn::sanitize_filename(file.original_filename)
      local_file_path = File.join(tmp_base_dir,@tmp_dir,@filename)
      
      # stored uploaded file into local_file_path
      # If it was a Tempfile object, the temporary file will be
      # cleaned up automatically, so we do not have to care for this
      if file.respond_to?(:local_path) and file.local_path and File.exists?(file.local_path)
        FileUtils.copy_file(file.local_path, local_file_path)
      elsif file.respond_to?(:read)
        File.open(local_file_path, "wb") { |f| f.write(file.read) }
      else
        raise ArgumentError.new("Do not know how to handle #{file.inspect}")
      end
      File.chmod(options[:permissions], local_file_path)
      
      if options[:fix_file_extensions]
        # try to determine correct file extension and fix
        # if necessary
        content_type = get_content_type((file.content_type.chomp if file.content_type))
        if content_type and options[:mime_extensions][content_type]
          @filename = correct_extension(@filename,options[:mime_extensions][content_type])
        end

        new_local_file_path = File.join(tmp_base_dir,@tmp_dir,@filename)
        File.rename(local_file_path, new_local_file_path) unless new_local_file_path == local_file_path
        local_file_path = new_local_file_path
      end
      
      @instance[@attr] = @filename
      @just_uploaded = true
    end


    # tries to identify and strip the extension of filename
    # if an regular expresion from EXT_REGEXPS matches and the
    # downcased extension is a known extension (in options[:extensions])
    # we'll strip this extension
    def strip_extension(filename)
      split_extension(filename).first
    end

    def correct_extension(filename, ext)
      strip_extension(filename) << ".#{ext}"
    end
    
    def parse_temp_path(temp_path, instance_options=nil)
      raise ArgumentError.new("invalid format of '#{temp_path}'") unless temp_path =~ %r{^((\d+\.)+\d+)/([^/].+)$}
      @tmp_dir, @filename = $1, FileColumn.sanitize_filename($3)
      @dir = File.join(tmp_base_dir, @tmp_dir)

      @instance[@attr] = @filename unless instance_options == :ignore_instance
    end
    
    def upload(file)
      # store new file
      temp = clone_as TempUploadedFile
      temp.store_upload(file)
      
      # delete old copy
      delete_files

      # and return new TempUploadedFile object
      temp
    end

    def delete
      delete_files
      @instance[@attr] = ""
      clone_as NoUploadedFile
    end

    def assign_temp(temp_path)
      return self if temp_path.nil? or temp_path.empty?
      # we can ignore this since we've already received a newly uploaded file

      # however, we delete the old temporary files
      temp = clone_as TempUploadedFile
      temp.parse_temp_path(temp_path, :ignore_instance)
      temp.delete_files

      self
    end

    def temp_path
      File.join(@tmp_dir, @filename)
    end

    def after_save
      super

      # we have a newly uploaded image, move it to the correct location
      file = clone_as PermanentUploadedFile
      file.move_from(File.join(tmp_base_dir, @tmp_dir), @just_uploaded)

      # delete temporary files
      delete_files

      # replace with the new PermanentUploadedFile object
      file
    end

    def delete_files
      FileUtils.rm_rf(File.join(tmp_base_dir, @tmp_dir))
    end

    def get_content_type(fallback=nil)
      if options[:file_exec]
        begin
          content_type = `#{options[:file_exec]} -bi "#{File.join(@dir,@filename)}"`.chomp
          content_type = fallback unless $?.success?
          content_type.gsub!(/;.+$/,"") if content_type
          content_type
        rescue
          fallback
        end
      else
        fallback
      end
    end

    private

    def relative_path_prefix
      File.join("tmp", @tmp_dir)
    end
  end

  
  class PermanentUploadedFile < RealUploadedFile # :nodoc:
    def initialize(*args)
      super *args
      @dir = File.join(store_dir, relative_path_prefix)
      @filename = @instance[@attr]
      @filename = nil if @filename.empty?
    end

    def move_from(local_dir, just_uploaded)
      # remove old permament dir first
      # this creates a short moment, where neither the old nor
      # the new files exist but we can't do much about this as
      # filesystems aren't transactional.
      FileUtils.rm_rf @dir

      FileUtils.mv local_dir, @dir

      @just_uploaded = just_uploaded
    end

    def upload(file)
      temp = clone_as TempUploadedFile
      temp.store_upload(file)
      temp
    end

    def delete
      file = clone_as NoUploadedFile
      @instance[@attr] = ""
      file.on_save { delete_files }
      file
    end

    def assign_temp(temp_path)
      return nil if temp_path.nil? or temp_path.empty?

      temp = clone_as TempUploadedFile
      temp.parse_temp_path(temp_path)
      temp
    end

    def after_destroy
      delete_files
    end

    def delete_files
      FileUtils.rm_rf @dir
    end

    private
    
    def relative_path_prefix
      raise RuntimeError.new("Trying to access file_column, but primary key got lost.") if @instance.id.to_s.empty?
      @instance.id.to_s
    end
  end
    
  # The FileColumn module allows you to easily handle file uploads. You can designate
  # one or more columns of your model's table as "file columns" like this:
  #
  #   class Entry < ActiveRecord::Base
  #
  #     file_column :image
  #   end
  #
  # Now, by default, an uploaded file "test.png" for an entry object with primary key 42 will
  # be stored in in "public/entry/image/42/test.png". The filename "test.png" will be stored
  # in the record's "image" column. The "entries" table should have a +VARCHAR+ column
  # named "image".
  #
  # The methods of this module are automatically included into <tt>ActiveRecord::Base</tt>
  # as class methods, so that you can use them in your models.
  #
  # == Generated Methods
  #
  # After calling "<tt>file_column :image</tt>" as in the example above, a number of instance methods
  # will automatically be generated, all prefixed by "image":
  #
  # * <tt>Entry#image=(uploaded_file)</tt>: this will handle a newly uploaded file
  #   (see below). Note that
  #   you can simply call your upload field "entry[image]" in your view (or use the
  #   helper).
  # * <tt>Entry#image(subdir=nil)</tt>: This will return an absolute path (as a
  #   string) to the currently uploaded file
  #   or nil if no file has been uploaded
  # * <tt>Entry#image_relative_path(subdir=nil)</tt>: This will return a path relative to
  #   this file column's base directory
  #   as a string or nil if no file has been uploaded. This would be "42/test.png" in the example.
  # * <tt>Entry#image_just_uploaded?</tt>: Returns true if a new file has been uploaded to this instance.
  #   You can use this in your code to perform certain actions (e. g., validation,
  #   custom post-processing) only on newly uploaded files.
  #
  # You can access the raw value of the "image" column (which will contain the filename) via the
  # <tt>ActiveRecord::Base#attributes</tt> or <tt>ActiveRecord::Base#[]</tt> methods like this:
  #
  #   entry['image']    # e.g."test.png"
  #
  # == Storage of uploaded files
  #
  # For a model class +Entry+ and a column +image+, all files will be stored under
  # "public/entry/image". A sub-directory named after the primary key of the object will
  # be created, so that files can be stored using their real filename. For example, a file
  # "test.png" stored in an Entry object with id 42 will be stored in
  #
  #   public/entry/image/42/test.png
  #
  # Files will be moved to this location in an +after_save+ callback. They will be stored in
  # a temporary location previously as explained in the next section.
  #
  # By default, files will be created with unix permissions of <tt>0644</tt> (i. e., owner has
  # read/write access, group and others only have read access). You can customize
  # this by passing the desired mode as a <tt>:permissions</tt> options. The value
  # you give here is passed directly to <tt>File::chmod</tt>, so on Unix you should
  # give some octal value like 0644, for example.
  #
  # == Handling of form redisplay
  #
  # Suppose you have a form for creating a new object where the user can upload an image. The form may
  # have to be re-displayed because of validation errors. The uploaded file has to be stored somewhere so
  # that the user does not have to upload it again. FileColumn will store these in a temporary directory
  # (called "tmp" and located under the column's base directory by default) so that it can be moved to
  # the final location if the object is successfully created. If the form is never completed, though, you
  # can easily remove all the images in this "tmp" directory once per day or so.
  #
  # So in the example above, the image "test.png" would first be stored in 
  # "public/entry/image/tmp/<some_random_key>/test.png" and be moved to
  # "public/entry/image/<primary_key>/test.png".
  #
  # This temporary location of newly uploaded files has another advantage when updating objects. If the
  # update fails for some reasons (e.g. due to validations), the existing image will not be overwritten, so
  # it has a kind of "transactional behaviour".
  #
  # == Additional Files and Directories
  #
  # FileColumn allows you to keep more than one file in a directory and will move/delete
  # all the files and directories it finds in a model object's directory when necessary.
  #
  # As a convenience you can access files stored in sub-directories via the +subdir+
  # parameter if they have the same filename.
  #
  # Suppose your uploaded file is named "vancouver.jpg" and you want to create a
  # thumb-nail and store it in the "thumb" directory. If you call
  # <tt>image("thumb")</tt>, you
  # will receive an absolute path for the file "thumb/vancouver.jpg" in the same
  # directory "vancouver.jpg" is stored. Look at the documentation of FileColumn::Magick
  # for more examples and how to create these thumb-nails automatically.
  #
  # == File Extensions
  #
  # FileColumn will try to fix the file extension of uploaded files, so that
  # the files are served with the correct mime-type by your web-server. Most
  # web-servers are setting the mime-type based on the file's extension. You
  # can disable this behaviour by passing the <tt>:fix_file_extensions</tt> option
  # with a value of +nil+ to +file_column+.
  #
  # In order to set the correct extension, FileColumn tries to determine
  # the files mime-type first. It then uses the +MIME_EXTENSIONS+ hash to
  # choose the corresponding file extension. You can override this hash
  # by passing in a <tt>:mime_extensions</tt> option to +file_column+.
  #
  # The mime-type of the uploaded file is determined with the following steps:
  #
  # 1. Run the external "file" utility. You can specify the full path to
  #    the executable in the <tt>:file_exec</tt> option or set this option
  #    to +nil+ to disable this step
  #
  # 2. If the file utility couldn't determine the mime-type or the utility was not
  #    present, the content-type provided by the user's browser is used
  #    as a fallback.
  #
  # == Custom Storage Directories
  #
  # FileColumn's storage location is determined in the following way. All
  # files are saved below the so-called "root_path" directory, which defaults to
  # "Rails.root/public". For every file_column, you can set a separte "store_dir"
  # option. It defaults to "model_name/attribute_name".
  # 
  # Files will always be stored in sub-directories of the store_dir path. The
  # subdirectory is named after the instance's +id+ attribute for a saved model,
  # or "tmp/<randomkey>" for unsaved models.
  #
  # You can specify a custom root_path by setting the <tt>:root_path</tt> option.
  # 
  # You can specify a custom storage_dir by setting the <tt>:storage_dir</tt> option.
  #
  # For setting a static storage_dir that doesn't change with respect to a particular
  # instance, you assign <tt>:storage_dir</tt> a String representing a directory
  # as an absolute path.
  #
  # If you need more fine-grained control over the storage directory, you
  # can use the name of a callback-method as a symbol for the
  # <tt>:store_dir</tt> option. This method has to be defined as an
  # instance method in your model. It will be called without any arguments
  # whenever the storage directory for an uploaded file is needed. It should return
  # a String representing a directory relativeo to root_path.
  #
  # Uploaded files for unsaved models objects will be stored in a temporary
  # directory. By default this directory will be a "tmp" directory in
  # your <tt>:store_dir</tt>. You can override this via the
  # <tt>:tmp_base_dir</tt> option.
  module ClassMethods

    # default mapping of mime-types to file extensions. FileColumn will try to
    # rename a file to the correct extension if it detects a known mime-type
    MIME_EXTENSIONS = {
      "image/gif" => "gif",
      "image/jpeg" => "jpg",
      "image/pjpeg" => "jpg",
      "image/x-png" => "png",
      "image/jpg" => "jpg",
      "image/png" => "png",
      "application/x-shockwave-flash" => "swf",
      "application/pdf" => "pdf",
      "application/pgp-signature" => "sig",
      "application/futuresplash" => "spl",
      "application/msword" => "doc",
      "application/postscript" => "ps",
      "application/x-bittorrent" => "torrent",
      "application/x-dvi" => "dvi",
      "application/x-gzip" => "gz",
      "application/x-ns-proxy-autoconfig" => "pac",
      "application/x-shockwave-flash" => "swf",
      "application/x-tgz" => "tar.gz",
      "application/x-tar" => "tar",
      "application/zip" => "zip",
      "audio/mpeg" => "mp3",
      "audio/x-mpegurl" => "m3u",
      "audio/x-ms-wma" => "wma",
      "audio/x-ms-wax" => "wax",
      "audio/x-wav" => "wav",
      "image/x-xbitmap" => "xbm",             
      "image/x-xpixmap" => "xpm",             
      "image/x-xwindowdump" => "xwd",             
      "text/css" => "css",             
      "text/html" => "html",                          
      "text/javascript" => "js",
      "text/plain" => "txt",
      "text/xml" => "xml",
      "video/mpeg" => "mpeg",
      "video/quicktime" => "mov",
      "video/x-msvideo" => "avi",
      "video/x-ms-asf" => "asf",
      "video/x-ms-wmv" => "wmv"
    }

    EXTENSIONS = Set.new MIME_EXTENSIONS.values
    EXTENSIONS.merge %w(jpeg)

    # default options. You can override these with +file_column+'s +options+ parameter
    DEFAULT_OPTIONS = {
      :root_path => File.join(Rails.root, "public"),
      :web_root => "",
      :mime_extensions => MIME_EXTENSIONS,
      :extensions => EXTENSIONS,
      :fix_file_extensions => true,
      :permissions => 0644,

      # path to the unix "file" executbale for
      # guessing the content-type of files
      :file_exec => "file" 
    }
    
    # handle the +attr+ attribute as a "file-upload" column, generating additional methods as explained
    # above. You should pass the attribute's name as a symbol, like this:
    #
    #   file_column :image
    #
    # You can pass in an options hash that overrides the options
    # in +DEFAULT_OPTIONS+.
    def file_column(attr, options={})
      options = DEFAULT_OPTIONS.merge(options) if options
      
      my_options = FileColumn::init_options(options, 
        ActiveSupport::Inflector.underscore(self.name).to_s,
                                            attr.to_s)
      
      state_attr = "@#{attr}_state".to_sym
      state_method = "#{attr}_state".to_sym
      
      define_method state_method do
        result = instance_variable_get state_attr
        if result.nil?
          result = FileColumn::create_state(self, attr.to_s)
          instance_variable_set state_attr, result
        end
        result
      end
      
      private state_method
      
      define_method attr do |*args|
        send(state_method).absolute_path *args
      end
      
      define_method "#{attr}_relative_path" do |*args|
        send(state_method).relative_path *args
      end

      define_method "#{attr}_dir" do
        send(state_method).absolute_dir
      end

      define_method "#{attr}_relative_dir" do
        send(state_method).relative_dir
      end

      define_method "#{attr}=" do |file|
        state = send(state_method).assign(file)
        instance_variable_set state_attr, state
        if state.options[:after_upload] and state.just_uploaded?
          state.options[:after_upload].each do |sym|
            self.send sym
          end
        end
      end
      
      define_method "#{attr}_temp" do
        send(state_method).temp_path
      end
      
      define_method "#{attr}_temp=" do |temp_path|
        instance_variable_set state_attr, send(state_method).assign_temp(temp_path)
      end
      
      after_save_method = "#{attr}_after_save".to_sym
      
      define_method after_save_method do
        instance_variable_set state_attr, send(state_method).after_save
      end
      
      after_save after_save_method
      
      after_destroy_method = "#{attr}_after_destroy".to_sym
      
      define_method after_destroy_method do
        send(state_method).after_destroy
      end
      after_destroy after_destroy_method
      
      define_method "#{attr}_just_uploaded?" do
        send(state_method).just_uploaded?
      end

      # this creates a closure keeping a reference to my_options
      # right now that's the only way we store the options. We
      # might use a class attribute as well
      define_method "#{attr}_options" do
        my_options
      end

      private after_save_method, after_destroy_method

      FileColumn::MagickExtension::file_column(self, attr, my_options) if options[:magick]
    end
    
  end
  
  private
  
  def self.generate_temp_name
    now = Time.now
    "#{now.to_i}.#{now.usec}.#{Process.pid}"
  end
  
  def self.sanitize_filename(filename)
    filename = File.basename(filename.gsub("\\", "/")) # work-around for IE
    filename.gsub!(/[^a-zA-Z0-9\.\-\+_]/,"_")
    filename = "_#{filename}" if filename =~ /^\.+$/
    filename = "unnamed" if filename.size == 0
    filename
  end
  
end


