require File.dirname(__FILE__) + '/abstract_unit'
require File.dirname(__FILE__) + '/fixtures/entry'

class UrlForFileColumnTest < Test::Unit::TestCase
  include FileColumnHelper

  def setup
    Entry.file_column :image
    @request = RequestMock.new
  end

  def test_url_for_file_column_with_temp_entry
    @e = Entry.new(:image => upload(f("skanthak.png")))
    url = url_for_file_column("e", "image")
    assert_match %r{^/entry/image/tmp/\d+(\.\d+)+/skanthak.png$}, url
  end

  def test_url_for_file_column_with_saved_entry
    @e = Entry.new(:image => upload(f("skanthak.png")))
    assert @e.save

    url = url_for_file_column("e", "image")
    assert_equal "/entry/image/#{@e.id}/skanthak.png", url
  end

  def test_url_for_file_column_works_with_symbol
    @e = Entry.new(:image => upload(f("skanthak.png")))
    assert @e.save

    url = url_for_file_column(:e, :image)
    assert_equal "/entry/image/#{@e.id}/skanthak.png", url
  end
  
  def test_url_for_file_column_works_with_object
    e = Entry.new(:image => upload(f("skanthak.png")))
    assert e.save

    url = url_for_file_column(e, "image")
    assert_equal "/entry/image/#{e.id}/skanthak.png", url
  end

  def test_url_for_file_column_should_return_nil_on_no_uploaded_file
    e = Entry.new
    assert_nil url_for_file_column(e, "image")
  end

  def test_url_for_file_column_without_extension
    e = Entry.new
    e.image = uploaded_file(file_path("kerb.jpg"), "something/unknown", "local_filename")
    assert e.save
    assert_equal "/entry/image/#{e.id}/local_filename", url_for_file_column(e, "image")
  end
end

class UrlForFileColumnTest < Test::Unit::TestCase
  include FileColumnHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  def setup
    Entry.file_column :image

    # mock up some request data structures for AssetTagHelper
    @request = RequestMock.new
    @request.relative_url_root = "/foo/bar"
    @controller = self
  end

  def request
    @request
  end

  IMAGE_URL = %r{^/foo/bar/entry/image/.+/skanthak.png$}
  def test_with_image_tag
    e = Entry.new(:image => upload(f("skanthak.png")))
    html = image_tag url_for_file_column(e, "image")
    url = html.scan(/src=\"(.+)\"/).first.first

    assert_match IMAGE_URL, url
  end

  def test_with_link_to_tag
    e = Entry.new(:image => upload(f("skanthak.png")))
    html = link_to "Download", url_for_file_column(e, "image", :absolute => true)
    url = html.scan(/href=\"(.+)\"/).first.first
    
    assert_match IMAGE_URL, url
  end

  def test_relative_url_root_not_modified
    e = Entry.new(:image => upload(f("skanthak.png")))
    url_for_file_column(e, "image", :absolute => true)
    
    assert_equal "/foo/bar", @request.relative_url_root
  end
end
