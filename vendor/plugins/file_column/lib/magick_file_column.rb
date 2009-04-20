module FileColumn # :nodoc:
  
  class BaseUploadedFile # :nodoc:
    def transform_with_magick
      if needs_transform?
        begin
          img = ::Magick::Image::read(absolute_path).first
        rescue ::Magick::ImageMagickError
          if options[:magick][:image_required]
            @magick_errors ||= []
            @magick_errors << "invalid image"
          end
          return
        end
        
        if options[:magick][:versions]
          options[:magick][:versions].each_pair do |version, version_options|
            next if version_options[:lazy]
            dirname = version_options[:name]
            FileUtils.mkdir File.join(@dir, dirname)
            transform_image(img, version_options, absolute_path(dirname))
          end
        end
        if options[:magick][:size] or options[:magick][:crop] or options[:magick][:transformation] or options[:magick][:attributes]
          transform_image(img, options[:magick], absolute_path)
        end

        GC.start
      end
    end

    def create_magick_version_if_needed(version)
      # RMagick might not have been loaded so far.
      # We do not want to require it on every call of this method
      # as this might be fairly expensive, so we just try if ::Magick
      # exists and require it if not.
      begin 
        ::Magick 
      rescue NameError
        require 'RMagick'
      end

      if version.is_a?(Symbol)
        version_options = options[:magick][:versions][version]
      else
        version_options = MagickExtension::process_options(version)
      end

      unless File.exists?(absolute_path(version_options[:name]))
        begin
          img = ::Magick::Image::read(absolute_path).first
        rescue ::Magick::ImageMagickError
          # we might be called directly from the view here
          # so we just return nil if we cannot load the image
          return nil
        end
        dirname = version_options[:name]
        FileUtils.mkdir File.join(@dir, dirname)
        transform_image(img, version_options, absolute_path(dirname))
      end

      version_options[:name]
    end

    attr_reader :magick_errors
    
    def has_magick_errors?
      @magick_errors and !@magick_errors.empty?
    end

    private
    
    def needs_transform?
      options[:magick] and just_uploaded? and 
        (options[:magick][:size] or options[:magick][:versions] or options[:magick][:transformation] or options[:magick][:attributes])
    end

    def transform_image(img, img_options, dest_path)
      begin
        if img_options[:transformation]
          if img_options[:transformation].is_a?(Symbol)
            img = @instance.send(img_options[:transformation], img)
          else
            img = img_options[:transformation].call(img)
          end
        end
        if img_options[:crop]
          dx, dy = img_options[:crop].split(':').map { |x| x.to_f }
          w, h = (img.rows * dx / dy), (img.columns * dy / dx)
          img = img.crop(::Magick::CenterGravity, [img.columns, w].min, 
                         [img.rows, h].min, true)
        end

        if img_options[:size]
          img = img.change_geometry(img_options[:size]) do |c, r, i|
            i.resize(c, r)
          end
        end
      ensure
        img.write(dest_path) do
          if img_options[:attributes]
            img_options[:attributes].each_pair do |property, value| 
              self.send "#{property}=", value
            end
          end
        end
        File.chmod options[:permissions], dest_path
      end
    end
  end

  # If you are using file_column to upload images, you can
  # directly process the images with RMagick,
  # a ruby extension
  # for accessing the popular imagemagick libraries. You can find
  # more information about RMagick at http://rmagick.rubyforge.org.
  #
  # You can control what to do by adding a <tt>:magick</tt> option
  # to your options hash. All operations are performed immediately
  # after a new file is assigned to the file_column attribute (i.e.,
  # when a new file has been uploaded).
  #
  # == Resizing images
  #
  # To resize the uploaded image according to an imagemagick geometry
  # string, just use the <tt>:size</tt> option:
  #
  #    file_column :image, :magick => {:size => "800x600>"}
  #
  # If the uploaded file cannot be loaded by RMagick, file_column will
  # signal a validation error for the corresponding attribute. If you
  # want to allow non-image files to be uploaded in a column that uses
  # the <tt>:magick</tt> option, you can set the <tt>:image_required</tt>
  # attribute to +false+:
  #
  #    file_column :image, :magick => {:size => "800x600>",
  #                                    :image_required => false }
  #
  # == Multiple versions
  #
  # You can also create additional versions of your image, for example
  # thumb-nails, like this:
  #    file_column :image, :magick => {:versions => {
  #         :thumb => {:size => "50x50"},
  #         :medium => {:size => "640x480>"}
  #       }
  #
  # These versions will be stored in separate sub-directories, named like the
  # symbol you used to identify the version. So in the previous example, the
  # image versions will be stored in "thumb", "screen" and "widescreen"
  # directories, resp. 
  # A name different from the symbol can be set via the <tt>:name</tt> option.
  #
  # These versions can be accessed via FileColumnHelper's +url_for_image_column+
  # method like this:
  #
  #    <%= url_for_image_column "entry", "image", :thumb %>
  #
  # == Cropping images
  #
  # If you wish to crop your images with a size ratio before scaling
  # them according to your version geometry, you can use the :crop directive.
  #    file_column :image, :magick => {:versions => {
  #         :square => {:crop => "1:1", :size => "50x50", :name => "thumb"},
  #         :screen => {:crop => "4:3", :size => "640x480>"},
  #         :widescreen => {:crop => "16:9", :size => "640x360!"},
  #       }
  #    }
  #
  # == Custom attributes
  #
  # To change some of the image properties like compression level before they
  # are saved you can set the <tt>:attributes</tt> option.
  # For a list of available attributes go to http://www.simplesystems.org/RMagick/doc/info.html
  # 
  #     file_column :image, :magick => { :attributes => { :quality => 30 } }
  # 
  # == Custom transformations
  #
  # To perform custom transformations on uploaded images, you can pass a
  # callback to file_column:
  #    file_column :image, :magick => 
  #       Proc.new { |image| image.quantize(256, Magick::GRAYColorspace) }
  #
  # The callback you give, receives one argument, which is an instance
  # of Magick::Image, the RMagick image class. It should return a transformed
  # image. Instead of passing a <tt>Proc</tt> object, you can also give a
  # <tt>Symbol</tt>, the name of an instance method of your model.
  #
  # Custom transformations can be combined via the standard :size and :crop
  # features, by using the :transformation option:
  #   file_column :image, :magick => {
  #      :transformation => Proc.new { |image| ... },
  #      :size => "640x480"
  #    }
  #
  # In this case, the standard resizing operations will be performed after the
  # custom transformation.
  #
  # Of course, custom transformations can be used in versions, as well.
  #
  # <b>Note:</b> You'll need the
  # RMagick extension being installed  in order to use file_column's
  # imagemagick integration.
  module MagickExtension

    def self.file_column(klass, attr, options) # :nodoc:
      require 'RMagick'
      options[:magick] = process_options(options[:magick],false) if options[:magick]
      if options[:magick][:versions]
        options[:magick][:versions].each_pair do |name, value|
          options[:magick][:versions][name] = process_options(value, name.to_s)
        end
      end
      state_method = "#{attr}_state".to_sym
      after_assign_method = "#{attr}_magick_after_assign".to_sym
      
      klass.send(:define_method, after_assign_method) do
        self.send(state_method).transform_with_magick
      end
      
      options[:after_upload] ||= []
      options[:after_upload] << after_assign_method
      
      klass.validate do |record|
        state = record.send(state_method)
        if state.has_magick_errors?
          state.magick_errors.each do |error|
            record.errors.add attr, error
          end
        end
      end
    end

    
    def self.process_options(options,create_name=true)
      case options
      when String then options = {:size => options}
      when Proc, Symbol then options = {:transformation => options }
      end
      if options[:geometry]
        options[:size] = options.delete(:geometry)
      end
      options[:image_required] = true unless options.key?(:image_required)
      if options[:name].nil? and create_name
        if create_name == true
          hash = 0
          for key in [:size, :crop]
            hash = hash ^ options[key].hash if options[key]
          end
          options[:name] = hash.abs.to_s(36)
        else
          options[:name] = create_name
        end
      end
      options
    end

  end
end
