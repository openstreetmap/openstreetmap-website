module FileColumn
  module Validations #:nodoc:
    
    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end

    # This module contains methods to create validations of uploaded files. All methods
    # in this module will be included as class methods into <tt>ActiveRecord::Base</tt>
    # so that you can use them in your models like this:
    #
    #    class Entry < ActiveRecord::Base
    #      file_column :image
    #      validates_filesize_of :image, :in => 0..1.megabyte
    #    end
    module ClassMethods
      EXT_REGEXP = /\.([A-z0-9]+)$/
    
      # This validates the file type of one or more file_columns.  A list of file columns
      # should be given followed by an options hash.
      #
      # Required options:
      # * <tt>:in</tt> => list of extensions or mime types. If mime types are used they
      #   will be mapped into an extension via FileColumn::ClassMethods::MIME_EXTENSIONS.
      #
      # Examples:
      #     validates_file_format_of :field, :in => ["gif", "png", "jpg"]
      #     validates_file_format_of :field, :in => ["image/jpeg"]
      def validates_file_format_of(*attrs)
      
        options = attrs.pop if attrs.last.is_a?Hash
        raise ArgumentError, "Please include the :in option." if !options || !options[:in]
        options[:in] = [options[:in]] if options[:in].is_a?String
        raise ArgumentError, "Invalid value for option :in" unless options[:in].is_a?Array
      
        validates_each(attrs, options) do |record, attr, value|
          unless value.blank?
            mime_extensions = record.send("#{attr}_options")[:mime_extensions]
            extensions = options[:in].map{|o| mime_extensions[o] || o }
            record.errors.add attr, "is not a valid format." unless extensions.include?(value.scan(EXT_REGEXP).flatten.first)
          end
        end
      
      end
    
      # This validates the file size of one or more file_columns.  A list of file columns
      # should be given followed by an options hash.
      #
      # Required options:
      # * <tt>:in</tt> => A size range.  Note that you can use ActiveSupport's
      #   numeric extensions for kilobytes, etc.
      #
      # Examples:
      #    validates_filesize_of :field, :in => 0..100.megabytes
      #    validates_filesize_of :field, :in => 15.kilobytes..1.megabyte
      def validates_filesize_of(*attrs)  
      
        options = attrs.pop if attrs.last.is_a?Hash
        raise ArgumentError, "Please include the :in option." if !options || !options[:in]
        raise ArgumentError, "Invalid value for option :in" unless options[:in].is_a?Range
      
        validates_each(attrs, options) do |record, attr, value|
          unless value.blank?
            size = File.size(value)
            record.errors.add attr, "is smaller than the allowed size range." if size < options[:in].first
            record.errors.add attr, "is larger than the allowed size range." if size > options[:in].last
          end
        end
      
      end 

      IMAGE_SIZE_REGEXP = /^(\d+)x(\d+)$/

      # Validates the image size of one or more file_columns.  A list of file columns
      # should be given followed by an options hash. The validation will pass
      # if both image dimensions (rows and columns) are at least as big as
      # given in the <tt>:min</tt> option.
      #
      # Required options:
      # * <tt>:min</tt> => minimum image dimension string, in the format NNxNN
      #   (columns x rows).
      #
      # Example:
      #    validates_image_size :field, :min => "1200x1800"
      #
      # This validation requires RMagick to be installed on your system
      # to check the image's size.
      def validates_image_size(*attrs)      
        options = attrs.pop if attrs.last.is_a?Hash
        raise ArgumentError, "Please include a :min option." if !options || !options[:min]
        minimums = options[:min].scan(IMAGE_SIZE_REGEXP).first.collect{|n| n.to_i} rescue []
        raise ArgumentError, "Invalid value for option :min (should be 'XXxYY')" unless minimums.size == 2

        require 'RMagick'

        validates_each(attrs, options) do |record, attr, value|
          unless value.blank?
            begin
              img = ::Magick::Image::read(value).first
              record.errors.add('image', "is too small, must be at least #{minimums[0]}x#{minimums[1]}") if ( img.rows < minimums[1] || img.columns < minimums[0] )
            rescue ::Magick::ImageMagickError
              record.errors.add('image', "invalid image")
            end
            img = nil
            GC.start
          end
        end
      end
    end
  end
end
