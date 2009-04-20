require 'test/unit'

# Add the methods +upload+, the <tt>setup_file_fixtures</tt> and
# <tt>teardown_file_fixtures</tt> to the class Test::Unit::TestCase.
class Test::Unit::TestCase
  # Returns a +Tempfile+ object as it would have been generated on file upload.
  # Use this method to create the parameters when emulating form posts with 
  # file fields.
  #
  # === Example:
  #
  #    def test_file_column_post
  #      entry = { :title => 'foo', :file => upload('/tmp/foo.txt')}
  #      post :upload, :entry => entry
  #  
  #      # ...
  #    end
  #
  # === Parameters
  #
  # * <tt>path</tt> The path to the file to upload.
  # * <tt>content_type</tt> The MIME type of the file. If it is <tt>:guess</tt>,
  #   the method will try to guess it.
  def upload(path, content_type=:guess, type=:tempfile)
    if content_type == :guess
      case path
      when /\.jpg$/ then content_type = "image/jpeg"
      when /\.png$/ then content_type = "image/png"
      else content_type = nil
      end
    end
    uploaded_file(path, content_type, File.basename(path), type)
  end
  
  # Copies the fixture files from "RAILS_ROOT/test/fixtures/file_column" into
  # the temporary storage directory used for testing
  # ("RAILS_ROOT/test/tmp/file_column"). Call this method in your
  # <tt>setup</tt> methods to get the file fixtures (images, for example) into
  # the directory used by file_column in testing.
  #
  # Note that the files and directories in the "fixtures/file_column" directory 
  # must have the same structure as you would expect in your "/public" directory
  # after uploading with FileColumn.
  #
  # For example, the directory structure could look like this:
  #
  #   test/fixtures/file_column/
  #   `-- container
  #       |-- first_image
  #       |   |-- 1
  #       |   |   `-- image1.jpg
  #       |   `-- tmp
  #       `-- second_image
  #           |-- 1
  #           |   `-- image2.jpg
  #           `-- tmp
  #
  # Your fixture file for this one "container" class fixture could look like this:
  #
  #   first:
  #     id:           1
  #     first_image:  image1.jpg
  #     second_image: image1.jpg
  #
  # A usage example:
  #
  #  def setup
  #    setup_fixture_files
  #
  #    # ...
  #  end
  def setup_fixture_files
    tmp_path = File.join(RAILS_ROOT, "test", "tmp", "file_column")
    file_fixtures = Dir.glob File.join(RAILS_ROOT, "test", "fixtures", "file_column", "*")
    
    FileUtils.mkdir_p tmp_path unless File.exists?(tmp_path)
    FileUtils.cp_r file_fixtures, tmp_path
  end
  
  # Removes the directory "RAILS_ROOT/test/tmp/file_column/" so the files
  # copied on test startup are removed. Call this in your unit test's +teardown+
  # method.
  #
  # A usage example:
  #
  #  def teardown
  #    teardown_fixture_files
  #
  #    # ...
  #  end
  def teardown_fixture_files
    FileUtils.rm_rf File.join(RAILS_ROOT, "test", "tmp", "file_column")
  end
  
  private
  
  def uploaded_file(path, content_type, filename, type=:tempfile) # :nodoc:
    if type == :tempfile
      t = Tempfile.new(File.basename(filename))
      FileUtils.copy_file(path, t.path)
    else
      if path
        t = StringIO.new(IO.read(path))
      else
        t = StringIO.new
      end
    end
    (class << t; self; end).class_eval do
      alias local_path path if type == :tempfile
      define_method(:local_path) { "" } if type == :stringio
      define_method(:original_filename) {filename}
      define_method(:content_type) {content_type}
    end
    return t
  end
end

# If we are running in the "test" environment, we overwrite the default 
# settings for FileColumn so that files are not uploaded into "/public/"
# in tests but rather into the directory "/test/tmp/file_column".
if RAILS_ENV == "test"
  FileColumn::ClassMethods::DEFAULT_OPTIONS[:root_path] =
    File.join(RAILS_ROOT, "test", "tmp", "file_column")
end
