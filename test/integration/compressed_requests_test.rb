require "test_helper"

class CompressedRequestsTest < ActionDispatch::IntegrationTest
  def test_no_compression
    user = create(:user)
    changeset = create(:changeset, :user => user)

    node = create(:node)
    way = create(:way)
    relation = create(:relation)
    other_relation = create(:relation)
    # Create some tags, since we test that they are removed later
    create(:node_tag, :node => node)
    create(:way_tag, :way => way)
    create(:relation_tag, :relation => relation)

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post "/api/0.6/changeset/#{changeset.id}/upload",
         :params => diff,
         :headers => {
           "HTTP_AUTHORIZATION" => format("Basic %{auth}", :auth => Base64.encode64("#{user.display_name}:test")),
           "HTTP_CONTENT_TYPE" => "application/xml"
         }
    assert_response :success,
                    "can't upload an uncompressed diff to changeset: #{@response.body}"

    # check that the changes made it into the database
    assert_equal 0, Node.find(node.id).tags.size, "node #{node.id} should now have no tags"
    assert_equal 0, Way.find(way.id).tags.size, "way #{way.id} should now have no tags"
    assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
  end

  def test_gzip_compression
    user = create(:user)
    changeset = create(:changeset, :user => user)

    node = create(:node)
    way = create(:way)
    relation = create(:relation)
    other_relation = create(:relation)
    # Create some tags, since we test that they are removed later
    create(:node_tag, :node => node)
    create(:way_tag, :way => way)
    create(:relation_tag, :relation => relation)

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post "/api/0.6/changeset/#{changeset.id}/upload",
         :params => gzip_content(diff),
         :headers => {
           "HTTP_AUTHORIZATION" => format("Basic %{auth}", :auth => Base64.encode64("#{user.display_name}:test")),
           "HTTP_CONTENT_ENCODING" => "gzip",
           "HTTP_CONTENT_TYPE" => "application/xml"
         }
    assert_response :success,
                    "can't upload a gzip compressed diff to changeset: #{@response.body}"

    # check that the changes made it into the database
    assert_equal 0, Node.find(node.id).tags.size, "node #{node.id} should now have no tags"
    assert_equal 0, Way.find(way.id).tags.size, "way #{way.id} should now have no tags"
    assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
  end

  def test_deflate_compression
    user = create(:user)
    changeset = create(:changeset, :user => user)

    node = create(:node)
    way = create(:way)
    relation = create(:relation)
    other_relation = create(:relation)
    # Create some tags, since we test that they are removed later
    create(:node_tag, :node => node)
    create(:way_tag, :way => way)
    create(:relation_tag, :relation => relation)

    # simple diff to change a node, way and relation by removing
    # their tags
    diff = <<CHANGESET.strip_heredoc
      <osmChange>
       <modify>
        <node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
        <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
         <nd ref='#{node.id}'/>
        </way>
       </modify>
       <modify>
        <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
         <member type='way' role='some' ref='#{way.id}'/>
         <member type='node' role='some' ref='#{node.id}'/>
         <member type='relation' role='some' ref='#{other_relation.id}'/>
        </relation>
       </modify>
      </osmChange>
CHANGESET

    # upload it
    post "/api/0.6/changeset/#{changeset.id}/upload",
         :params => deflate_content(diff),
         :headers => {
           "HTTP_AUTHORIZATION" => format("Basic %{auth}", :auth => Base64.encode64("#{user.display_name}:test")),
           "HTTP_CONTENT_ENCODING" => "deflate",
           "HTTP_CONTENT_TYPE" => "application/xml"
         }
    assert_response :success,
                    "can't upload a deflate compressed diff to changeset: #{@response.body}"

    # check that the changes made it into the database
    assert_equal 0, Node.find(node.id).tags.size, "node #{node.id} should now have no tags"
    assert_equal 0, Way.find(way.id).tags.size, "way #{way.id} should now have no tags"
    assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
  end

  def test_invalid_compression
    user = create(:user)
    changeset = create(:changeset, :user => user)

    # upload it
    post "/api/0.6/changeset/#{changeset.id}/upload",
         :params => "",
         :headers => {
           "HTTP_AUTHORIZATION" => format("Basic %{auth}", :auth => Base64.encode64("#{user.display_name}:test")),
           "HTTP_CONTENT_ENCODING" => "unknown",
           "HTTP_CONTENT_TYPE" => "application/xml"
         }
    assert_response :unsupported_media_type
  end

  private

  def gzip_content(uncompressed)
    compressed = StringIO.new
    gz = Zlib::GzipWriter.new(compressed)
    gz.write(uncompressed)
    gz.close
    compressed.string
  end

  def deflate_content(uncompressed)
    Zlib::Deflate.deflate(uncompressed)
  end
end
