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
    service = create_service(user, "direct-create-orig.test", "aaaa123456789012345678901234567890bbccdd")

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
    service = create_service(user, "direct-update.test", "aaaa123456789012345678901234567890bbccdd")

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
    service = create_service(user, "direct-destroy.test", "aaaa123456789012345678901234567890bbccdd")

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
    service = create_service(user, "retrieve-keys-empty.test", "aaaa123456789012345678901234567890bbccdd")

    get :retrieve_keys, :params => { :service => "retrieve-keys-empty.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert response.find("//osm/keyid").count.positive?
  end

  def test_index_edit_show
    user = create(:user)
    service = create_service(user, "index-edit-show.test", "aaaa123456789012345678901234567890bbccdd")

    basic_authorization user.email, "test"
    get :index
    assert :success

    basic_authorization user.email, "test"
    get :show, :params => { :id => service.id }
    assert :success

    basic_authorization user.email, "test"
    get :edit, :params => { :id => service.id }
    assert :success
  end

  def test_retrieve_keys_full
    user_one = create(:user)
    user_two = create(:user)
    user_three = create(:user)
    user_four = create(:user)
    service = create_service(user_one, "retrieve-keys-full.test", "aaaa123456789012345678901234567890bbccdd")

    # Create three keys
    key_event_one = create_key_event
    key_one = create_key(key_event_one, "01cccc123456789012345678901234567890bbccdd", user_one, service)

    key_event_two = create_key_event
    key_two = create_key(key_event_two, "02cccc123456789012345678901234567890bbccdd", user_two, service)
    assert key_one.created_ref < key_two.created_ref

    key_event_three = create_key_event
    key_three = create_key(key_event_three, "03cccc123456789012345678901234567890bbccdd", user_three, service)
    assert key_two.created_ref < key_three.created_ref

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_three.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [key_one, key_two, key_three])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_one.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_three.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [key_two, key_three])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_two.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_three.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [key_three])

    # Revoke one key
    key_event_four = create_key_event
    key_one.revoked_ref = key_event_four.id
    assert key_one.save
    assert key_three.created_ref < key_one.revoked_ref

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [key_two, key_three])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_one.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [key_one])
    assert_apikeys_match(response, [key_two, key_three])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_four.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [])

    # Create another one
    key_event_five = create_key_event
    key_four = create_key(key_event_five, "05cccc123456789012345678901234567890bbccdd", user_four, service)

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => 0 }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [key_two, key_three, key_four])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_one.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [key_one])
    assert_apikeys_match(response, [key_two, key_three, key_four])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_four.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [key_four])

    get :retrieve_keys, :params => { :service => "retrieve-keys-full.test", :key => service.access_key,
                                     :beyond => key_event_five.id }
    assert :success
    response = XML::Parser.string(@response.body).parse
    assert_keyid_present(response, key_event_four.id)
    assert_revokeds_match(response, [])
    assert_apikeys_match(response, [])
  end

  private

  def create_service(user, uri, access_key)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = uri
    service.access_key = access_key
    assert service.save
    service
  end

  def create_key(created, data, user, service)
    key = ThirdPartyKey.new
    key.created_ref = created.id
    key.data = data
    key.user_ref = user.id
    key.third_party_service = service
    assert key.save
    key
  end

  def create_key_event
    key_event = ThirdPartyKeyEvent.new
    assert key_event.save
    key_event
  end

  def assert_keyid_present(response, min_val)
    keyid_nodes = response.find("//osm/keyid")
    assert keyid_nodes.count == 1
    assert keyid_nodes[0]["max"] && keyid_nodes[0]["max"].to_f && keyid_nodes[0]["max"].to_f >= min_val
  end

  def assert_revokeds_match(response, expected)
    revokeds = response.find("//osm/revoked")
    assert revokeds.count == expected.count
    (0..(expected.count - 1)).each do |i|
      assert revokeds[i]["key"]
      assert revokeds[i]["key"] == expected[i].data
    end
  end

  def assert_apikeys_match(response, expected)
    apikeys = response.find("//osm/apikey")
    assert apikeys.count == expected.count
    (0..(expected.count - 1)).each do |i|
      assert apikeys[i]["key"] && apikeys[i]["created"]
      assert apikeys[i]["key"] == expected[i].data
    end
  end
end
