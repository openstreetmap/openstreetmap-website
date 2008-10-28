module FileColumn

  # This bit of code allows you to pass regular old files to
  # file_column.  file_column depends on a few extra methods that the
  # CGI uploaded file class adds.  We will add the equivalent methods
  # to file objects if necessary by extending them with this module. This
  # avoids opening up the standard File class which might result in
  # naming conflicts.

  module FileCompat # :nodoc:
    def original_filename
      File.basename(path)
    end
    
    def size
      File.size(path)
    end
    
    def local_path
      path
    end
    
    def content_type
      nil
    end
  end
end

