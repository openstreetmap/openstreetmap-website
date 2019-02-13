require "test_helper"

class ThirdPartyServicesControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/third_party_services", :method => :post },
      { :controller => "third_party_services", :action => "create" }
    )
    assert_routing(
      { :path => "/third_party_services", :method => :get },
      { :controller => "third_party_services", :action => "index" }
    )
    assert_routing(
      { :path => "/third_party_services/1", :method => :get },
      { :controller => "third_party_services", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/third_party_services/1/edit", :method => :get },
      { :controller => "third_party_services", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/third_party_services/1", :method => :put },
      { :controller => "third_party_services", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/third_party_services/1", :method => :delete },
      { :controller => "third_party_services", :action => "destroy", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/third_party_services/keys", :method => :get },
      { :controller => "third_party_services", :action => "retrieve_keys" }
    )
  end

  def test_direct_create
    user = create(:user)

    post :create
    assert_response :unauthorized, "third_party_services create did not return unauthorized status"

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_service => { :uri => "direct-create.test" } }
    assert_response :redirect, "third_party_services create did not forward to show"

    service = ThirdPartyService.find_by uri: "direct-create.test"
    assert service
    assert service.user_ref == user.id
    assert service.uri == "direct-create.test"
    assert service.access_key && service.access_key.length == 40
  end

  def test_no_double_create
    user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "direct-create-orig.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    alt_user = create(:user)
    assert user.id != alt_user.id && user.email != alt_user.email

    basic_authorization alt_user.email, "test"
    post :create, :params => { :third_party_service => { :uri => "direct-create-orig.test" } }

    found_services = ThirdPartyService.where(uri: "direct-create-orig.test")
    assert found_services.count == 1
    assert found_services[0].id == service.id
    assert found_services[0].user_ref == user.id

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_service => { :uri => "direct-create-orig.test" } }

    found_services = ThirdPartyService.where(uri: "direct-create-orig.test")
    assert found_services.count == 1
    assert found_services[0].id == service.id
    assert found_services[0].user_ref == user.id
  end

  def test_direct_update
    user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "direct-update.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    alt_user = create(:user)
    assert user.id != alt_user.id && user.email != alt_user.email

    basic_authorization alt_user.email, "test"
    put :update, :params => { :id => service.id }

    found_services = ThirdPartyService.where(uri: "direct-update.test")
    assert found_services.count == 1
    assert found_services[0].id == service.id
    assert found_services[0].user_ref == user.id
    assert found_services[0].access_key == service.access_key

    basic_authorization user.email, "test"
    put :update, :params => { :id => service.id }

    found_services = ThirdPartyService.where(uri: "direct-update.test")
    assert found_services.count == 1
    assert found_services[0].id == service.id
    assert found_services[0].user_ref == user.id
    assert found_services[0].access_key && found_services[0].access_key.length == 40
    assert found_services[0].access_key != service.access_key
  end

  def test_direct_destroy
    user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "direct-destroy.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    alt_user = create(:user)
    assert user.id != alt_user.id && user.email != alt_user.email

    basic_authorization alt_user.email, "test"
    post :destroy, :params => { :id => service.id }
    assert_response :redirect, "third_party_services create did not forward to show for foreign user"

    found_service = ThirdPartyService.find_by uri: "direct-destroy.test"
    assert found_service
    assert found_service.user_ref = user.id
    assert found_service.access_key && found_service.access_key.length == 40

    basic_authorization user.email, "test"
    post :destroy, :params => { :id => service.id }
    assert_response :redirect, "third_party_services create did not forward to show after revoking key"

    found_service = ThirdPartyService.find_by uri: "direct-destroy.test"
    assert found_service
    assert found_service.user_ref = user.id
    assert found_service.access_key == ""
  end

  def test_retrieve_keys_empty
    user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "retrieve-keys-empty.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    get :retrieve_keys, :params => { :service => "retrieve-keys-empty.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert response.find("//osm/keyid").count > 0
  end

  def test_retrieve_keys_full
    user_1 = create(:user)
    user_2 = create(:user)
    user_3 = create(:user)
    user_4 = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user_1.id
    service.uri = "retrieve-keys-full.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    # Create three keys
    key_event_1 = ThirdPartyKeyEvent.new
    assert key_event_1.save
    key_1 = ThirdPartyKey.new
    key_1.created_ref = key_event_1.id
    key_1.data = "01cccc123456789012345678901234567890bbccdd"
    key_1.user_ref = user_1.id
    key_1.third_party_service = service
    assert key_1.save

    key_event_2 = ThirdPartyKeyEvent.new
    assert key_event_2.save
    key_2 = ThirdPartyKey.new
    key_2.created_ref = key_event_2.id
    key_2.data = "02cccc123456789012345678901234567890bbccdd"
    key_2.user_ref = user_2.id
    key_2.third_party_service = service
    assert key_2.save
    assert key_1.created_ref < key_2.created_ref

    key_event_3 = ThirdPartyKeyEvent.new
    assert key_event_3.save
    key_3 = ThirdPartyKey.new
    key_3.created_ref = key_event_3.id
    key_3.data = "03cccc123456789012345678901234567890bbccdd"
    key_3.user_ref = user_3.id
    key_3.third_party_service = service
    assert key_3.save
    assert key_2.created_ref < key_3.created_ref

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_3.id
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 3
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_1.data
    assert apikeys[1]["key"] == key_2.data
    assert apikeys[2]["key"] == key_3.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_1.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_3.id
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 2
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_2.data
    assert apikeys[1]["key"] == key_3.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_2.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_3.id
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 1
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_3.data

    # Revoke one key
    key_event_4 = ThirdPartyKeyEvent.new
    assert key_event_4.save
    key_1.revoked_ref = key_event_4.id
    assert key_1.save
    assert key_3.created_ref < key_1.revoked_ref

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 0
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 2
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_2.data
    assert apikeys[1]["key"] == key_3.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_1.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 1
    assert revoked_keys[0]["key"]
    assert revoked_keys[0]["key"] == key_1.data
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 2
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_2.data
    assert apikeys[1]["key"] == key_3.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_4.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 0
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 0

    # Create another one
    key_event_5 = ThirdPartyKeyEvent.new
    assert key_event_5.save
    key_4 = ThirdPartyKey.new
    key_4.created_ref = key_event_5.id
    key_4.data = "05cccc123456789012345678901234567890bbccdd"
    key_4.user_ref = user_4.id
    key_4.third_party_service = service
    assert key_4.save

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 0
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 3
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_2.data
    assert apikeys[1]["key"] == key_3.data
    assert apikeys[2]["key"] == key_4.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_1.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 1
    assert revoked_keys[0]["key"]
    assert revoked_keys[0]["key"] == key_1.data
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 3
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_2.data
    assert apikeys[1]["key"] == key_3.data
    assert apikeys[2]["key"] == key_4.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_4.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 0
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 1
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_4.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_5.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"]  && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_4.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 0
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 0
  end
end
