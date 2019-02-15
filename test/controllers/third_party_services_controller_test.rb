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

    service = ThirdPartyService.find_by :uri => "direct-create.test"
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

    found_services = ThirdPartyService.where(:uri => "direct-create-orig.test")
    assert found_services.count == 1
    assert found_services[0].id == service.id
    assert found_services[0].user_ref == user.id

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_service => { :uri => "direct-create-orig.test" } }

    found_services = ThirdPartyService.where(:uri => "direct-create-orig.test")
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

    found_services = ThirdPartyService.where(:uri => "direct-update.test")
    assert found_services.count == 1
    assert found_services[0].id == service.id
    assert found_services[0].user_ref == user.id
    assert found_services[0].access_key == service.access_key

    basic_authorization user.email, "test"
    put :update, :params => { :id => service.id }

    found_services = ThirdPartyService.where(:uri => "direct-update.test")
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

    found_service = ThirdPartyService.find_by :uri => "direct-destroy.test"
    assert found_service
    assert found_service.user_ref = user.id
    assert found_service.access_key && found_service.access_key.length == 40

    basic_authorization user.email, "test"
    post :destroy, :params => { :id => service.id }
    assert_response :redirect, "third_party_services create did not forward to show after revoking key"

    found_service = ThirdPartyService.find_by :uri => "direct-destroy.test"
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
    assert response.find("//osm/keyid").count.positive?
  end

  def test_retrieve_keys_full
    user_one = create(:user)
    user_two = create(:user)
    user_three = create(:user)
    user_four = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user_one.id
    service.uri = "retrieve-keys-full.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    # Create three keys
    key_event_one = ThirdPartyKeyEvent.new
    assert key_event_one.save
    key_one = ThirdPartyKey.new
    key_one.created_ref = key_event_one.id
    key_one.data = "01cccc123456789012345678901234567890bbccdd"
    key_one.user_ref = user_one.id
    key_one.third_party_service = service
    assert key_one.save

    key_event_two = ThirdPartyKeyEvent.new
    assert key_event_two.save
    key_two = ThirdPartyKey.new
    key_two.created_ref = key_event_two.id
    key_two.data = "02cccc123456789012345678901234567890bbccdd"
    key_two.user_ref = user_two.id
    key_two.third_party_service = service
    assert key_two.save
    assert key_one.created_ref < key_two.created_ref

    key_event_three = ThirdPartyKeyEvent.new
    assert key_event_three.save
    key_three = ThirdPartyKey.new
    key_three.created_ref = key_event_three.id
    key_three.data = "03cccc123456789012345678901234567890bbccdd"
    key_three.user_ref = user_three.id
    key_three.third_party_service = service
    assert key_three.save
    assert key_two.created_ref < key_three.created_ref

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_three.id
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 3
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_one.data
    assert apikeys[1]["key"] == key_two.data
    assert apikeys[2]["key"] == key_three.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_one.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_three.id
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 2
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_two.data
    assert apikeys[1]["key"] == key_three.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_two.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_three.id
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 1
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_three.data

    # Revoke one key
    key_event_four = ThirdPartyKeyEvent.new
    assert key_event_four.save
    key_one.revoked_ref = key_event_four.id
    assert key_one.save
    assert key_three.created_ref < key_one.revoked_ref

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count.zero?
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 2
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_two.data
    assert apikeys[1]["key"] == key_three.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_one.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 1
    assert revoked_keys[0]["key"]
    assert revoked_keys[0]["key"] == key_one.data
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 2
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_two.data
    assert apikeys[1]["key"] == key_three.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_four.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count.zero?
    apikeys = response.find("//osm/apikey")
    assert apikeys.count.zero?

    # Create another one
    key_event_five = ThirdPartyKeyEvent.new
    assert key_event_five.save
    key_four = ThirdPartyKey.new
    key_four.created_ref = key_event_five.id
    key_four.data = "05cccc123456789012345678901234567890bbccdd"
    key_four.user_ref = user_four.id
    key_four.third_party_service = service
    assert key_four.save

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count.zero?
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 3
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_two.data
    assert apikeys[1]["key"] == key_three.data
    assert apikeys[2]["key"] == key_four.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_one.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count == 1
    assert revoked_keys[0]["key"]
    assert revoked_keys[0]["key"] == key_one.data
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 3
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_two.data
    assert apikeys[1]["key"] == key_three.data
    assert apikeys[2]["key"] == key_four.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_four.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count.zero?
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == 1
    apikeys.each do |key|
      assert key["key"] && key["created"]
    end
    assert apikeys[0]["key"] == key_four.data

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_five.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= key_event_four.id
    revoked_keys = response.find("//osm/revoked")
    assert revoked_keys.count.zero?
    apikeys = response.find("//osm/apikey")
    assert apikeys.count.zero?
  end
end
