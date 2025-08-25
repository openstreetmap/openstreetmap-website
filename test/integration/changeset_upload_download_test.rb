# frozen_string_literal: true

require "test_helper"

class ChangesetUploadDownloadTest < ActionDispatch::IntegrationTest
  ##
  # when we make some simple changes we get the same changes back from the
  # diff download.
  def test_diff_download_simple
    node = create(:node)

    ## First try with a non-public user, which should get a forbidden
    auth_header = bearer_authorization_header create(:user, :data_public => false)

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    post api_changesets_path, :params => xml, :headers => auth_header
    assert_response :forbidden

    ## Now try with a normal user
    auth_header = bearer_authorization_header

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    post api_changesets_path, :params => xml, :headers => auth_header
    assert_response :success
    changeset_id = @response.body.to_i

    # add a diff to it
    diff = <<~CHANGESET
      <osmChange>
        <modify>
          <node id='#{node.id}' lon='0.0' lat='0.0' changeset='#{changeset_id}' version='1'/>
          <node id='#{node.id}' lon='0.1' lat='0.0' changeset='#{changeset_id}' version='2'/>
          <node id='#{node.id}' lon='0.1' lat='0.1' changeset='#{changeset_id}' version='3'/>
          <node id='#{node.id}' lon='0.1' lat='0.2' changeset='#{changeset_id}' version='4'/>
          <node id='#{node.id}' lon='0.2' lat='0.2' changeset='#{changeset_id}' version='5'/>
          <node id='#{node.id}' lon='0.3' lat='0.2' changeset='#{changeset_id}' version='6'/>
          <node id='#{node.id}' lon='0.3' lat='0.3' changeset='#{changeset_id}' version='7'/>
          <node id='#{node.id}' lon='0.9' lat='0.9' changeset='#{changeset_id}' version='8'/>
        </modify>
      </osmChange>
    CHANGESET

    # upload it
    post api_changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
    assert_response :success,
                    "can't upload multiple versions of an element in a diff: #{@response.body}"

    get api_changeset_download_path(changeset_id)
    assert_response :success

    assert_dom "osmChange", 1
    assert_dom "osmChange>modify", 8
    assert_dom "osmChange>modify>node", 8
  end

  ##
  # culled this from josm to ensure that nothing in the way that josm
  # is formatting the request is causing it to fail.
  #
  # NOTE: the error turned out to be something else completely!
  def test_josm_upload
    auth_header = bearer_authorization_header

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    post api_changesets_path, :params => xml, :headers => auth_header
    assert_response :success
    changeset_id = @response.body.to_i

    diff = <<~OSMFILE
      <osmChange version="0.6" generator="JOSM">
        <create version="0.6" generator="JOSM">
          <node id='-1' visible='true' changeset='#{changeset_id}' lat='51.49619982187321' lon='-0.18722061869438314' />
          <node id='-2' visible='true' changeset='#{changeset_id}' lat='51.496359883909605' lon='-0.18653093576241928' />
          <node id='-3' visible='true' changeset='#{changeset_id}' lat='51.49598132358285' lon='-0.18719613290981638' />
          <node id='-4' visible='true' changeset='#{changeset_id}' lat='51.4961591711078' lon='-0.18629015888084607' />
          <node id='-5' visible='true' changeset='#{changeset_id}' lat='51.49582126021711' lon='-0.18708186591517145' />
          <node id='-6' visible='true' changeset='#{changeset_id}' lat='51.49591018437858' lon='-0.1861432441734455' />
          <node id='-7' visible='true' changeset='#{changeset_id}' lat='51.49560784152179' lon='-0.18694719410005425' />
          <node id='-8' visible='true' changeset='#{changeset_id}' lat='51.49567389979617' lon='-0.1860289771788006' />
          <node id='-9' visible='true' changeset='#{changeset_id}' lat='51.49543761398892' lon='-0.186820684213126' />
          <way id='-10' action='modify' visible='true' changeset='#{changeset_id}'>
            <nd ref='-1' />
            <nd ref='-2' />
            <nd ref='-3' />
            <nd ref='-4' />
            <nd ref='-5' />
            <nd ref='-6' />
            <nd ref='-7' />
            <nd ref='-8' />
            <nd ref='-9' />
            <tag k='highway' v='residential' />
            <tag k='name' v='Foobar Street' />
          </way>
        </create>
      </osmChange>
    OSMFILE

    # upload it
    post api_changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
    assert_response :success,
                    "can't upload a diff from JOSM: #{@response.body}"

    get api_changeset_download_path(changeset_id)
    assert_response :success

    assert_dom "osmChange", 1
    assert_dom "osmChange>create>node", 9
    assert_dom "osmChange>create>way", 1
    assert_dom "osmChange>create>way>nd", 9
    assert_dom "osmChange>create>way>tag", 2
  end

  ##
  # when we make some complex changes we get the same changes back from the
  # diff download.
  def test_diff_download_complex
    node = create(:node)
    node2 = create(:node)
    way = create(:way)
    auth_header = bearer_authorization_header

    # create a temporary changeset
    xml = "<osm><changeset>" \
          "<tag k='created_by' v='osm test suite checking changesets'/>" \
          "</changeset></osm>"
    post api_changesets_path, :params => xml, :headers => auth_header
    assert_response :success
    changeset_id = @response.body.to_i

    # add a diff to it
    diff = <<~CHANGESET
      <osmChange>
        <delete>
          <node id='#{node.id}' lon='0.0' lat='0.0' changeset='#{changeset_id}' version='1'/>
        </delete>
        <create>
          <node id='-1' lon='0.9' lat='0.9' changeset='#{changeset_id}' version='0'/>
          <node id='-2' lon='0.8' lat='0.9' changeset='#{changeset_id}' version='0'/>
          <node id='-3' lon='0.7' lat='0.9' changeset='#{changeset_id}' version='0'/>
        </create>
        <modify>
          <node id='#{node2.id}' lon='2.0' lat='1.5' changeset='#{changeset_id}' version='1'/>
          <way id='#{way.id}' changeset='#{changeset_id}' version='1'>
            <nd ref='#{node2.id}'/>
            <nd ref='-1'/>
            <nd ref='-2'/>
            <nd ref='-3'/>
          </way>
        </modify>
      </osmChange>
    CHANGESET

    # upload it
    post api_changeset_upload_path(changeset_id), :params => diff, :headers => auth_header
    assert_response :success,
                    "can't upload multiple versions of an element in a diff: #{@response.body}"

    get api_changeset_download_path(changeset_id)
    assert_response :success

    assert_dom "osmChange", 1
    assert_dom "osmChange>create", 3
    assert_dom "osmChange>delete", 1
    assert_dom "osmChange>modify", 2
    assert_dom "osmChange>create>node", 3
    assert_dom "osmChange>delete>node", 1
    assert_dom "osmChange>modify>node", 1
    assert_dom "osmChange>modify>way", 1
  end
end
