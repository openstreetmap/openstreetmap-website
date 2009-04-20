require File.dirname(__FILE__) + '/abstract_unit'

require File.dirname(__FILE__) + '/fixtures/entry'

class Movie < ActiveRecord::Base
end


class FileColumnTest < Test::Unit::TestCase
  
  def setup
    # we define the file_columns here so that we can change
    # settings easily in a single test

    Entry.file_column :image
    Entry.file_column :file
    Movie.file_column :movie

    clear_validations
  end
  
  def teardown
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/entry/"
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/movie/"
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/my_store_dir/"
  end
  
  def test_column_write_method
    assert Entry.new.respond_to?("image=")
  end
  
  def test_column_read_method
    assert Entry.new.respond_to?("image")
  end
  
  def test_sanitize_filename
    assert_equal "test.jpg", FileColumn::sanitize_filename("test.jpg")
    assert FileColumn::sanitize_filename("../../very_tricky/foo.bar") !~ /[\\\/]/, "slashes not removed"
    assert_equal "__foo", FileColumn::sanitize_filename('`*foo')
    assert_equal "foo.txt", FileColumn::sanitize_filename('c:\temp\foo.txt')
    assert_equal "_.", FileColumn::sanitize_filename(".")
  end
  
  def test_default_options
    e = Entry.new
    assert_match %r{/public/entry/image}, e.image_options[:store_dir]
    assert_match %r{/public/entry/image/tmp}, e.image_options[:tmp_base_dir]
  end
  
  def test_assign_without_save_with_tempfile
    do_test_assign_without_save(:tempfile)
  end
  
  def test_assign_without_save_with_stringio
    do_test_assign_without_save(:stringio)
  end
  
  def do_test_assign_without_save(upload_type)
    e = Entry.new
    e.image = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png", upload_type)
    assert e.image.is_a?(String), "#{e.image.inspect} is not a String"
    assert File.exists?(e.image)
    assert FileUtils.identical?(e.image, file_path("skanthak.png"))
  end
  
  def test_filename_preserved
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "local_filename.jpg")
    assert_equal "local_filename.jpg", File.basename(e.image)
  end
  
  def test_filename_stored_in_attribute
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert_equal "kerb.jpg", e["image"]
  end
  
  def test_extension_added
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "local_filename")
    assert_equal "local_filename.jpg", File.basename(e.image)
    assert_equal "local_filename.jpg", e["image"]
  end

  def test_no_extension_without_content_type
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "something/unknown", "local_filename")
    assert_equal "local_filename", File.basename(e.image)
    assert_equal "local_filename", e["image"]
  end

  def test_extension_unknown_type
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "not/known", "local_filename")
    assert_equal "local_filename", File.basename(e.image)
    assert_equal "local_filename", e["image"]
  end

  def test_extension_unknown_type_with_extension
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "not/known", "local_filename.abc")
    assert_equal "local_filename.abc", File.basename(e.image)
    assert_equal "local_filename.abc", e["image"]
  end

  def test_extension_corrected
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "local_filename.jpeg")
    assert_equal "local_filename.jpg", File.basename(e.image)
    assert_equal "local_filename.jpg", e["image"]
  end

  def test_double_extension
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "application/x-tgz", "local_filename.tar.gz")
    assert_equal "local_filename.tar.gz", File.basename(e.image)
    assert_equal "local_filename.tar.gz", e["image"]
  end

  FILE_UTILITY = "/usr/bin/file"

  def test_get_content_type_with_file
    Entry.file_column :image, :file_exec => FILE_UTILITY

    # run this test only if the machine we are running on
    # has the file utility installed
    if File.executable?(FILE_UTILITY)
      e = Entry.new
      file = FileColumn::TempUploadedFile.new(e, "image")
      file.instance_variable_set :@dir, File.dirname(file_path("kerb.jpg"))
      file.instance_variable_set :@filename, File.basename(file_path("kerb.jpg"))
      
      assert_equal "image/jpeg", file.get_content_type
    else
      puts "Warning: Skipping test_get_content_type_with_file test as '#{options[:file_exec]}' does not exist"
    end
  end

  def test_fix_extension_with_file
    Entry.file_column :image, :file_exec => FILE_UTILITY

    # run this test only if the machine we are running on
    # has the file utility installed
    if File.executable?(FILE_UTILITY)
      e = Entry.new(:image => uploaded_file(file_path("skanthak.png"), "", "skanthak.jpg"))
      
      assert_equal "skanthak.png", File.basename(e.image)
    else
      puts "Warning: Skipping test_fix_extension_with_file test as '#{options[:file_exec]}' does not exist"
    end
  end

  def test_do_not_fix_file_extensions
    Entry.file_column :image, :fix_file_extensions => false

    e = Entry.new(:image => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb"))

    assert_equal "kerb", File.basename(e.image)
  end

  def test_correct_extension
    e = Entry.new
    file = FileColumn::TempUploadedFile.new(e, "image")
    
    assert_equal "filename.jpg", file.correct_extension("filename.jpeg","jpg")
    assert_equal "filename.tar.gz", file.correct_extension("filename.jpg","tar.gz")
    assert_equal "filename.jpg", file.correct_extension("filename.tar.gz","jpg")
    assert_equal "Protokoll_01.09.2005.doc", file.correct_extension("Protokoll_01.09.2005","doc")
    assert_equal "strange.filenames.exist.jpg", file.correct_extension("strange.filenames.exist","jpg")
    assert_equal "another.strange.one.jpg", file.correct_extension("another.strange.one.png","jpg")
  end

  def test_assign_with_save
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    tmp_file_path = e.image
    assert e.save
    assert File.exists?(e.image)
    assert FileUtils.identical?(e.image, file_path("kerb.jpg"))
    assert_equal "#{e.id}/kerb.jpg", e.image_relative_path
    assert !File.exists?(tmp_file_path), "temporary file '#{tmp_file_path}' not removed"
    assert !File.exists?(File.dirname(tmp_file_path)), "temporary directory '#{File.dirname(tmp_file_path)}' not removed"
    
    local_path = e.image
    e = Entry.find(e.id)
    assert_equal local_path, e.image
  end

  def test_dir_methods
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    e.save
    
    assert_equal_paths File.join(RAILS_ROOT, "public", "entry", "image", e.id.to_s), e.image_dir
    assert_equal File.join(e.id.to_s), e.image_relative_dir
  end

  def test_store_dir_callback
    Entry.file_column :image, {:store_dir => :my_store_dir}
    e = Entry.new

    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")    
    assert e.save
    
    assert_equal_paths File.join(RAILS_ROOT, "public", "my_store_dir", e.id), e.image_dir   
  end

  def test_tmp_dir_with_store_dir_callback
    Entry.file_column :image, {:store_dir => :my_store_dir}
    e = Entry.new
    e.image = upload(f("kerb.jpg"))
    
    assert_equal File.expand_path(File.join(RAILS_ROOT, "public", "my_store_dir", "tmp")), File.expand_path(File.join(e.image_dir,".."))
  end

  def test_invalid_store_dir_callback
    Entry.file_column :image, {:store_dir => :my_store_dir_doesnt_exit}    
    e = Entry.new
    assert_raise(ArgumentError) {
      e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
      e.save
    }
  end

  def test_subdir_parameter
    e = Entry.new
    assert_nil e.image("thumb")
    assert_nil e.image_relative_path("thumb")
    assert_nil e.image(nil)

    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    
    assert_equal "kerb.jpg", File.basename(e.image("thumb"))
    assert_equal "kerb.jpg", File.basename(e.image_relative_path("thumb"))

    assert_equal File.join(e.image_dir,"thumb","kerb.jpg"), e.image("thumb")
    assert_match %r{/thumb/kerb\.jpg$}, e.image_relative_path("thumb") 

    assert_equal e.image, e.image(nil)
    assert_equal e.image_relative_path, e.image_relative_path(nil)
  end

  def test_cleanup_after_destroy
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    local_path = e.image
    assert File.exists?(local_path)
    assert e.destroy
    assert !File.exists?(local_path), "'#{local_path}' still exists although entry was destroyed"
    assert !File.exists?(File.dirname(local_path))
  end
  
  def test_keep_tmp_image
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    e.validation_should_fail = true
    assert !e.save, "e should not save due to validation errors"
    assert File.exists?(local_path = e.image)
    image_temp = e.image_temp
    e = Entry.new("image_temp" => image_temp)
    assert_equal local_path, e.image
    assert e.save
    assert FileUtils.identical?(e.image, file_path("kerb.jpg"))
  end
  
  def test_keep_tmp_image_with_existing_image
    e = Entry.new("image" =>uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    assert File.exists?(local_path = e.image)
    e = Entry.find(e.id)
    e.image = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    e.validation_should_fail = true
    assert !e.save
    temp_path = e.image_temp
    e = Entry.find(e.id)
    e.image_temp = temp_path
    assert e.save
    
    assert FileUtils.identical?(e.image, file_path("skanthak.png"))
    assert !File.exists?(local_path), "old image has not been deleted"
  end
  
  def test_replace_tmp_image_temp_first
    do_test_replace_tmp_image([:image_temp, :image])
  end
  
  def test_replace_tmp_image_temp_last
    do_test_replace_tmp_image([:image, :image_temp])
  end
  
  def do_test_replace_tmp_image(order)
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    e.validation_should_fail = true
    assert !e.save
    image_temp = e.image_temp
    temp_path = e.image
    new_img = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    e = Entry.new
    for method in order
      case method
      when :image_temp then e.image_temp = image_temp
      when :image then e.image = new_img
      end
    end
    assert e.save
    assert FileUtils.identical?(e.image, file_path("skanthak.png")), "'#{e.image}' is not the expected 'skanthak.png'"
    assert !File.exists?(temp_path), "temporary file '#{temp_path}' is not cleaned up"
    assert !File.exists?(File.dirname(temp_path)), "temporary directory not cleaned up"
    assert e.image_just_uploaded?
  end
  
  def test_replace_image_on_saved_object
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    old_file = e.image
    e = Entry.find(e.id)
    e.image = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    assert e.save
    assert FileUtils.identical?(file_path("skanthak.png"), e.image)
    assert old_file != e.image
    assert !File.exists?(old_file), "'#{old_file}' has not been cleaned up"
  end
  
  def test_edit_without_touching_image
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    e = Entry.find(e.id)
    assert e.save
    assert FileUtils.identical?(file_path("kerb.jpg"), e.image)
  end
  
  def test_save_without_image
    e = Entry.new
    assert e.save
    e.reload
    assert_nil e.image
  end
  
  def test_delete_saved_image
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    assert e.save
    local_path = e.image
    e.image = nil
    assert_nil e.image
    assert File.exists?(local_path), "file '#{local_path}' should not be deleted until transaction is saved"
    assert e.save
    assert_nil e.image
    assert !File.exists?(local_path)
    e.reload
    assert e["image"].blank?
    e = Entry.find(e.id)
    assert_nil e.image
  end
  
  def test_delete_tmp_image
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    local_path = e.image
    e.image = nil
    assert_nil e.image
    assert e["image"].blank?
    assert !File.exists?(local_path)
  end
  
  def test_delete_nonexistant_image
    e = Entry.new
    e.image = nil
    assert e.save
    assert_nil e.image
  end

  def test_delete_image_on_non_null_column
    e = Entry.new("file" => upload(f("skanthak.png")))
    assert e.save

    local_path = e.file
    assert File.exists?(local_path)
    e.file = nil
    assert e.save
    assert !File.exists?(local_path)
  end

  def test_ie_filename
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'c:\images\kerb.jpg'))
    assert e.image_relative_path =~ /^tmp\/[\d\.]+\/kerb\.jpg$/, "relative path '#{e.image_relative_path}' was not as expected"
    assert File.exists?(e.image)
  end
  
  def test_just_uploaded?
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'c:\images\kerb.jpg'))
    assert e.image_just_uploaded?
    assert e.save
    assert e.image_just_uploaded?
    
    e = Entry.new("image" => uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'kerb.jpg'))
    temp_path = e.image_temp
    e = Entry.new("image_temp" => temp_path)
    assert !e.image_just_uploaded?
    assert e.save
    assert !e.image_just_uploaded?
  end
  
  def test_empty_tmp
    e = Entry.new
    e.image_temp = ""
    assert_nil e.image
  end
  
  def test_empty_tmp_with_image
    e = Entry.new
    e.image_temp = ""
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", 'c:\images\kerb.jpg')
    local_path = e.image
    assert File.exists?(local_path)
    e.image_temp = ""
    assert local_path, e.image
  end
  
  def test_empty_filename
    e = Entry.new
    assert_equal "", e["file"]
    assert_nil e.file
    assert_nil e["image"]
    assert_nil e.image
  end
  
  def test_with_two_file_columns
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg")
    e.file = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    assert e.save
    assert_match %{/entry/image/}, e.image
    assert_match %{/entry/file/}, e.file
    assert FileUtils.identical?(e.image, file_path("kerb.jpg"))
    assert FileUtils.identical?(e.file, file_path("skanthak.png"))
  end
  
  def test_with_two_models
    e = Entry.new(:image => uploaded_file(file_path("kerb.jpg"), "image/jpeg", "kerb.jpg"))
    m = Movie.new(:movie => uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png"))
    assert e.save
    assert m.save
    assert_match %{/entry/image/}, e.image
    assert_match %{/movie/movie/}, m.movie
    assert FileUtils.identical?(e.image, file_path("kerb.jpg"))
    assert FileUtils.identical?(m.movie, file_path("skanthak.png"))
  end

  def test_no_file_uploaded
    e = Entry.new
    assert_nothing_raised { e.image =
        uploaded_file(nil, "application/octet-stream", "", :stringio) }
    assert_equal nil, e.image
  end

  # when safari submits a form where no file has been
  # selected, it does not transmit a content-type and
  # the result is an empty string ""
  def test_no_file_uploaded_with_safari
    e = Entry.new
    assert_nothing_raised { e.image = "" }
    assert_equal nil, e.image
  end

  def test_detect_wrong_encoding
    e = Entry.new
    assert_raise(TypeError) { e.image ="img42.jpg" }
  end

  def test_serializable_before_save
    e = Entry.new
    e.image = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    assert_nothing_raised { 
      flash = Marshal.dump(e) 
      e = Marshal.load(flash)
    }
    assert File.exists?(e.image)
  end

  def test_should_call_after_upload_on_new_upload
    Entry.file_column :image, :after_upload => [:after_assign]
    e = Entry.new
    e.image = upload(f("skanthak.png"))
    assert e.after_assign_called?
  end

  def test_should_call_user_after_save_on_save
    e = Entry.new(:image => upload(f("skanthak.png")))
    assert e.save
    
    assert_kind_of FileColumn::PermanentUploadedFile, e.send(:image_state)
    assert e.after_save_called?
  end


  def test_assign_standard_files
    e = Entry.new
    e.image = File.new(file_path('skanthak.png'))
    
    assert_equal 'skanthak.png', File.basename(e.image)
    assert FileUtils.identical?(file_path('skanthak.png'), e.image)
    
    assert e.save
  end


  def test_validates_filesize
    Entry.validates_filesize_of :image, :in => 50.kilobytes..100.kilobytes

    e = Entry.new(:image => upload(f("kerb.jpg")))
    assert e.save

    e.image = upload(f("skanthak.png"))
    assert !e.save
    assert e.errors.invalid?("image")
  end

  def test_validates_file_format_simple
    e = Entry.new(:image => upload(f("skanthak.png")))
    assert e.save
    
    Entry.validates_file_format_of :image, :in => ["jpg"]

    e.image = upload(f("kerb.jpg"))
    assert e.save

    e.image = upload(f("mysql.sql"))
    assert !e.save
    assert e.errors.invalid?("image")
    
  end

  def test_validates_image_size
    Entry.validates_image_size :image, :min => "640x480"
    
    e = Entry.new(:image => upload(f("kerb.jpg")))
    assert e.save

    e = Entry.new(:image => upload(f("skanthak.png")))
    assert !e.save
    assert e.errors.invalid?("image")
  end

  def do_permission_test(uploaded_file, permissions=0641)
    Entry.file_column :image, :permissions => permissions
    
    e = Entry.new(:image => uploaded_file)
    assert e.save

    assert_equal permissions, (File.stat(e.image).mode & 0777)
  end

  def test_permissions_with_small_file
    do_permission_test upload(f("skanthak.png"), :guess, :stringio)
  end

  def test_permission_with_big_file
    do_permission_test upload(f("kerb.jpg"))
  end

  def test_permission_that_overrides_umask
    do_permission_test upload(f("skanthak.png"), :guess, :stringio), 0666
    do_permission_test upload(f("kerb.jpg")), 0666
  end

  def test_access_with_empty_id
    # an empty id might happen after a clone or through some other
    # strange event. Since we would create a path that contains nothing
    # where the id would have been, we should fail fast with an exception
    # in this case
    
    e = Entry.new(:image => upload(f("skanthak.png")))
    assert e.save
    id = e.id

    e = Entry.find(id)
    
    e["id"] = ""
    assert_raise(RuntimeError) { e.image }
    
    e = Entry.find(id)
    e["id"] = nil
    assert_raise(RuntimeError) { e.image }
  end
end

# Tests for moving temp dir to permanent dir
class FileColumnMoveTest < Test::Unit::TestCase
  
  def setup
    # we define the file_columns here so that we can change
    # settings easily in a single test

    Entry.file_column :image
    
  end
  
  def teardown
    FileUtils.rm_rf File.dirname(__FILE__)+"/public/entry/"
  end

  def test_should_move_additional_files_from_tmp
    e = Entry.new
    e.image = uploaded_file(file_path("skanthak.png"), "image/png", "skanthak.png")
    FileUtils.cp file_path("kerb.jpg"), File.dirname(e.image)
    assert e.save
    dir = File.dirname(e.image)
    assert File.exists?(File.join(dir, "skanthak.png"))
    assert File.exists?(File.join(dir, "kerb.jpg"))
  end

  def test_should_move_direcotries_on_save
    e = Entry.new(:image => upload(f("skanthak.png")))
    
    FileUtils.mkdir( e.image_dir+"/foo" )
    FileUtils.cp file_path("kerb.jpg"), e.image_dir+"/foo/kerb.jpg"
    
    assert e.save

    assert File.exists?(e.image)
    assert File.exists?(File.dirname(e.image)+"/foo/kerb.jpg")
  end

  def test_should_overwrite_dirs_with_files_on_reupload
    e = Entry.new(:image => upload(f("skanthak.png")))

    FileUtils.mkdir( e.image_dir+"/kerb.jpg")
    FileUtils.cp file_path("kerb.jpg"), e.image_dir+"/kerb.jpg/"
    assert e.save

    e.image = upload(f("kerb.jpg"))
    assert e.save

    assert File.file?(e.image_dir+"/kerb.jpg")
  end

  def test_should_overwrite_files_with_dirs_on_reupload
    e = Entry.new(:image => upload(f("skanthak.png")))

    assert e.save
    assert File.file?(e.image_dir+"/skanthak.png")

    e.image = upload(f("kerb.jpg"))
    FileUtils.mkdir(e.image_dir+"/skanthak.png")
    
    assert e.save
    assert File.file?(e.image_dir+"/kerb.jpg")
    assert !File.file?(e.image_dir+"/skanthak.png")
    assert File.directory?(e.image_dir+"/skanthak.png")
  end

end

