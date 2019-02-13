require "test_helper"

class ThirdPartyKeysControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/third_party_keys", :method => :post },
      { :controller => "third_party_keys", :action => "create" }
    )
    assert_routing(
      { :path => "/third_party_keys", :method => :get },
      { :controller => "third_party_keys", :action => "index" }
    )
    assert_routing(
      { :path => "/third_party_keys/1", :method => :get },
      { :controller => "third_party_keys", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/third_party_keys/1/edit", :method => :get },
      { :controller => "third_party_keys", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/third_party_keys/1", :method => :put },
      { :controller => "third_party_keys", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/third_party_keys/1", :method => :delete },
      { :controller => "third_party_keys", :action => "destroy", :id => "1" }
    )
  end

  def test_direct_create
    user = create(:user)
    alt_user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "key-create.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 0

    post :create
    assert_response :unauthorized, "third_party_keys create did not return unauthorized status"

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 0

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_key =>
        { :gdpr => "0", :attentive => "1", :disclose => "0", :service_to_use => "key-create.test" } }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 0

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_key =>
        { :gdpr => "1", :attentive => "1", :disclose => "0", :service_to_use => "key-create.test" } }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 0

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_key =>
        { :gdpr => "1", :attentive => "0", :disclose => "1", :service_to_use => "key-create.test" } }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 0

    basic_authorization user.email, "test"
    post :create, :params => { :third_party_key =>
        { :gdpr => "1", :attentive => "0", :disclose => "0", :service_to_use => "key-create.test" } }
    assert_response :redirect, "third_party_keys create did not forward to show"

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 1
    assert found_keys[0].user_ref == user.id
    assert found_keys[0].data && found_keys[0].data.length == 40
    assert found_keys[0].created_ref > 0
    assert !found_keys[0].revoked_ref

    basic_authorization alt_user.email, "test"
    post :create, :params => { :third_party_key =>
        { :gdpr => "1", :attentive => "0", :disclose => "0", :service_to_use => "key-create.test" } }
    assert_response :redirect, "third_party_keys create did not forward to show"

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 2
    assert ((found_keys[0].user_ref == user.id && found_keys[1].user_ref == alt_user.id) || (found_keys[1].user_ref == user.id && found_keys[0].user_ref == alt_user.id))
    assert found_keys[0].data && found_keys[0].data.length == 40
    assert found_keys[1].data && found_keys[1].data.length == 40
    assert found_keys[0].data != found_keys[1].data
    assert found_keys[0].created_ref > 0 && !found_keys[0].revoked_ref
    assert found_keys[1].created_ref > 0 && !found_keys[1].revoked_ref
  end

  def test_direct_update
    user = create(:user)
    alt_user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "key-update.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    #Create key to update
    key_event_1 = ThirdPartyKeyEvent.new
    assert key_event_1.save
    old_key = ThirdPartyKey.new
    old_key.created_ref = key_event_1.id
    old_key.data = "cccccc123456789012345678901234567890bbccdd"
    old_key.user_ref = alt_user.id
    old_key.third_party_service = service
    assert old_key.save

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 1
    assert found_keys[0].user_ref == alt_user.id
    assert found_keys[0].data == "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[0].created_ref == key_event_1.id && !found_keys[0].revoked_ref

    # User A cannot change user B's key
    basic_authorization user.email, "test"
    put :update, :params => { :id => old_key.id }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 1
    assert found_keys[0].user_ref == alt_user.id
    assert found_keys[0].data == "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[0].created_ref == key_event_1.id && !found_keys[0].revoked_ref

    # An update triggers a revoke plus a new key
    basic_authorization alt_user.email, "test"
    put :update, :params => { :id => old_key.id }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 2
    assert found_keys[0].user_ref == alt_user.id && found_keys[1].user_ref == alt_user.id
    assert found_keys[0].data == "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[1].data && found_keys[1].data.length == 40
    assert found_keys[1].data != "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[0].created_ref == key_event_1.id && found_keys[0].revoked_ref > 0
    assert found_keys[1].created_ref > 0 && !found_keys[1].revoked_ref
  end

  def test_direct_destroy
    user = create(:user)
    alt_user = create(:user)
    service = ThirdPartyService.new
    service.user_ref = user.id
    service.uri = "key-update.test"
    service.access_key = "aaaa123456789012345678901234567890bbccdd"
    assert service.save

    #Create key to delete
    key_event_1 = ThirdPartyKeyEvent.new
    assert key_event_1.save
    old_key = ThirdPartyKey.new
    old_key.created_ref = key_event_1.id
    old_key.data = "cccccc123456789012345678901234567890bbccdd"
    old_key.user_ref = alt_user.id
    old_key.third_party_service = service
    assert old_key.save

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 1
    assert found_keys[0].user_ref == alt_user.id
    assert found_keys[0].data == "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[0].created_ref == key_event_1.id && !found_keys[0].revoked_ref

    # User A cannot delete user B's key
    basic_authorization user.email, "test"
    put :destroy, :params => { :id => old_key.id }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 1
    assert found_keys[0].user_ref == alt_user.id
    assert found_keys[0].data == "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[0].created_ref == key_event_1.id && !found_keys[0].revoked_ref

    # An update fills revoked_ref with a meaningful reference
    basic_authorization alt_user.email, "test"
    put :destroy, :params => { :id => old_key.id }

    found_keys = ThirdPartyKey.where(third_party_service_id: service)
    assert found_keys.count == 1
    assert found_keys[0].user_ref == alt_user.id
    assert found_keys[0].data == "cccccc123456789012345678901234567890bbccdd"
    assert found_keys[0].created_ref == key_event_1.id && found_keys[0].revoked_ref > 0
  end
end
