require "test_helper"
require "gpx"

class TraceTest < ActiveSupport::TestCase
  def test_visible
    public_trace_file = create(:trace)
    create(:trace, :deleted)
    check_query(Trace.visible, [public_trace_file])
  end

  def test_visible_to
    first_user = create(:user)
    second_user = create(:user)
    third_user = create(:user)
    fourth_user = create(:user)
    public_trace_file = create(:trace, :visibility => "public", :user => first_user)
    anon_trace_file = create(:trace, :visibility => "private", :user => second_user)
    identifiable_trace_file = create(:trace, :visibility => "identifiable", :user => first_user)
    pending_trace_file = create(:trace, :visibility => "public", :user => second_user, :inserted => false)
    trackable_trace_file = create(:trace, :visibility => "trackable", :user => second_user)
    _other_trace_file = create(:trace, :visibility => "private", :user => third_user)

    check_query(Trace.visible_to(first_user), [
                  public_trace_file, identifiable_trace_file, pending_trace_file
                ])
    check_query(Trace.visible_to(second_user), [
                  public_trace_file, anon_trace_file, trackable_trace_file,
                  identifiable_trace_file, pending_trace_file
                ])
    check_query(Trace.visible_to(fourth_user), [
                  public_trace_file, identifiable_trace_file, pending_trace_file
                ])
  end

  def test_visible_to_all
    public_trace_file = create(:trace, :visibility => "public")
    _private_trace_file = create(:trace, :visibility => "private")
    identifiable_trace_file = create(:trace, :visibility => "identifiable")
    _trackable_trace_file = create(:trace, :visibility => "trackable")
    deleted_trace_file = create(:trace, :deleted, :visibility => "public")
    pending_trace_file = create(:trace, :visibility => "public", :inserted => false)

    check_query(Trace.visible_to_all, [
                  public_trace_file, identifiable_trace_file,
                  deleted_trace_file, pending_trace_file
                ])
  end

  def test_tagged
    london_trace_file = create(:trace) do |trace|
      create(:tracetag, :trace => trace, :tag => "London")
    end
    birmingham_trace_file = create(:trace) do |trace|
      create(:tracetag, :trace => trace, :tag => "Birmingham")
    end
    check_query(Trace.tagged("London"), [london_trace_file])
    check_query(Trace.tagged("Birmingham"), [birmingham_trace_file])
    check_query(Trace.tagged("Unknown"), [])
  end

  def test_validations
    trace_valid({})
    trace_valid({ :user_id => nil }, :valid => false)
    trace_valid({ :name => "a" * 255 })
    trace_valid({ :name => "a" * 256 }, :valid => false)
    trace_valid({ :description => nil }, :valid => false)
    trace_valid({ :description => "a" * 255 })
    trace_valid({ :description => "a" * 256 }, :valid => false)
    trace_valid({ :visibility => "private" })
    trace_valid({ :visibility => "public" })
    trace_valid({ :visibility => "trackable" })
    trace_valid({ :visibility => "identifiable" })
    trace_valid({ :visibility => "foo" }, :valid => false)
  end

  def test_tagstring_handles_space_separated_tags
    trace = build(:trace)
    trace.tagstring = "foo bar baz"
    assert_predicate trace, :valid?
    assert_equal 3, trace.tags.length
    assert_equal "foo", trace.tags[0].tag
    assert_equal "bar", trace.tags[1].tag
    assert_equal "baz", trace.tags[2].tag
    assert_equal "foo, bar, baz", trace.tagstring
  end

  def test_tagstring_handles_comma_separated_tags
    trace = build(:trace)
    trace.tagstring = "foo, bar baz ,qux"
    assert_predicate trace, :valid?
    assert_equal 3, trace.tags.length
    assert_equal "foo", trace.tags[0].tag
    assert_equal "bar baz", trace.tags[1].tag
    assert_equal "qux", trace.tags[2].tag
    assert_equal "foo, bar baz, qux", trace.tagstring
  end

  def test_tagstring_strips_whitespace
    trace = build(:trace)
    trace.tagstring = "   zero  ,  one , two  "
    assert_predicate trace, :valid?
    assert_equal 3, trace.tags.length
    assert_equal "zero", trace.tags[0].tag
    assert_equal "one", trace.tags[1].tag
    assert_equal "two", trace.tags[2].tag
    assert_equal "zero, one, two", trace.tagstring
  end

  def test_public?
    assert_predicate build(:trace, :visibility => "public"), :public?
    assert_not build(:trace, :visibility => "private").public?
    assert_not build(:trace, :visibility => "trackable").public?
    assert_predicate build(:trace, :visibility => "identifiable"), :public?
    assert_predicate build(:trace, :deleted, :visibility => "public"), :public?
  end

  def test_trackable?
    assert_not build(:trace, :visibility => "public").trackable?
    assert_not build(:trace, :visibility => "private").trackable?
    assert_predicate build(:trace, :visibility => "trackable"), :trackable?
    assert_predicate build(:trace, :visibility => "identifiable"), :trackable?
    assert_not build(:trace, :deleted, :visibility => "public").trackable?
  end

  def test_identifiable?
    assert_not build(:trace, :visibility => "public").identifiable?
    assert_not build(:trace, :visibility => "private").identifiable?
    assert_not build(:trace, :visibility => "trackable").identifiable?
    assert_predicate build(:trace, :visibility => "identifiable"), :identifiable?
    assert_not build(:trace, :deleted, :visibility => "public").identifiable?
  end

  def test_mime_type
    # The ids refer to the .gpx fixtures in test/traces
    check_mime_type("a", "application/gpx+xml")
    check_mime_type("b", "application/gpx+xml")
    check_mime_type("c", "application/x-bzip2")
    check_mime_type("d", "application/gzip")
    check_mime_type("f", "application/zip")
    check_mime_type("g", "application/x-tar")
    check_mime_type("h", "application/x-tar+gzip")
    check_mime_type("i", "application/x-tar+x-bzip2")
  end

  def test_extension_name
    # The ids refer to the .gpx fixtures in test/traces
    check_extension_name("a", ".gpx")
    check_extension_name("b", ".gpx")
    check_extension_name("c", ".gpx.bz2")
    check_extension_name("d", ".gpx.gz")
    check_extension_name("f", ".zip")
    check_extension_name("g", ".tar")
    check_extension_name("h", ".tar.gz")
    check_extension_name("i", ".tar.bz2")
  end

  def test_xml_file
    check_xml_file("a", "848caa72f2f456d1bd6a0fdf228aa1b9")
    check_xml_file("b", "db4cb5ed2d7d2b627b3b504296c4f701")
    check_xml_file("c", "848caa72f2f456d1bd6a0fdf228aa1b9")
    check_xml_file("d", "abd6675fdf3024a84fc0a1deac147c0d")
    check_xml_file("f", "a7c05d676c77dc14369c21be216a3713")
    check_xml_file("g", "a7c05d676c77dc14369c21be216a3713")
    check_xml_file("h", "a7c05d676c77dc14369c21be216a3713")
    check_xml_file("i", "a7c05d676c77dc14369c21be216a3713")
  end

  def test_large_picture
    picture = Rails.root.join("test/gpx/fixtures/a.gif").read(:mode => "rb")
    trace = create(:trace, :fixture => "a")

    assert_equal picture, trace.large_picture
  end

  def test_icon_picture
    picture = Rails.root.join("test/gpx/fixtures/a_icon.gif").read(:mode => "rb")
    trace = create(:trace, :fixture => "a")

    assert_equal picture, trace.icon_picture
  end

  def test_import_removes_previous_tracepoints
    trace = create(:trace, :fixture => "a")
    # Tracepoints don't have a primary key, so we use a specific latitude to
    # check for successful deletion
    create(:tracepoint, :latitude => 54321, :trace => trace)
    assert_equal 1, Tracepoint.where(:latitude => 54321).count

    trace.import

    assert_equal 0, Tracepoint.where(:latitude => 54321).count
  end

  def test_import_creates_tracepoints
    trace = create(:trace, :fixture => "a")
    assert_equal 0, Tracepoint.where(:gpx_id => trace.id).count

    trace.import

    trace.reload
    assert_equal 1, Tracepoint.where(:gpx_id => trace.id).count

    # Check that the tile has been set prior to the bulk import
    # i.e. that the callbacks have been run correctly
    assert_equal 3221331576, Tracepoint.where(:gpx_id => trace.id).first.tile
  end

  def test_import_creates_icon
    trace = create(:trace, :inserted => false, :fixture => "a")

    assert_not trace.icon.attached?

    trace.import

    assert_predicate trace.icon, :attached?
  end

  def test_import_creates_large_picture
    trace = create(:trace, :inserted => false, :fixture => "a")

    assert_not trace.image.attached?

    trace.import

    assert_predicate trace.image, :attached?
  end

  def test_import_handles_bz2
    trace = create(:trace, :inserted => false, :fixture => "c")

    trace.import

    assert_equal 1, trace.size
  end

  def test_import_handles_plain
    trace = create(:trace, :inserted => false, :fixture => "a")

    trace.import

    assert_equal 1, trace.size
  end

  def test_import_handles_plain_with_bom
    trace = create(:trace, :inserted => false, :fixture => "b")

    trace.import

    assert_equal 1, trace.size
  end

  def test_import_handles_gz
    trace = create(:trace, :inserted => false, :fixture => "d")

    trace.import

    assert_equal 1, trace.size
  end

  def test_import_handles_zip
    trace = create(:trace, :inserted => false, :fixture => "f")

    trace.import

    assert_equal 2, trace.size
  end

  def test_import_handles_tar
    trace = create(:trace, :inserted => false, :fixture => "g")

    trace.import

    assert_equal 2, trace.size
  end

  def test_import_handles_tar_gz
    trace = create(:trace, :inserted => false, :fixture => "h")

    trace.import

    assert_equal 2, trace.size
  end

  def test_import_handles_tar_bz2
    trace = create(:trace, :inserted => false, :fixture => "i")

    trace.import

    assert_equal 2, trace.size
  end

  private

  def check_query(query, traces)
    traces = traces.map(&:id).sort
    assert_equal traces, query.order(:id).ids
  end

  def check_mime_type(id, mime_type)
    assert_equal mime_type, create(:trace, :fixture => id).mime_type
  end

  def check_extension_name(id, extension_name)
    assert_equal extension_name, create(:trace, :fixture => id).extension_name
  end

  def check_xml_file(id, md5sum)
    assert_equal md5sum, md5sum(create(:trace, :fixture => id).xml_file)
  end

  def trace_valid(attrs, valid: true)
    entry = build(:trace, attrs)
    assert_equal valid, entry.valid?, "Expected #{attrs.inspect} to be #{valid}"
  end

  def md5sum(io)
    io.each_with_object(Digest::MD5.new) { |l, d| d.update(l) }.hexdigest
  end
end
