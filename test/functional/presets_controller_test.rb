require 'test_helper'

class PresetsControllerTest < ActionController::TestCase
  fixtures :users, :presets

  setup do
    @preset = presets(:one)
  end

  def test_routes
    assert_routing(
      { :path => "/api/0.6/presets", :method => :post },
      { :controller => "presets", :action => "create" }
    )
    assert_routing(
      { :path => "/api/0.6/presets/1", :method => :get },
      { :controller => "presets", :action => "show", :id => "1" }
    )
    assert_recognizes(
      { :controller => "presets", :action => "show", :id => "1", :format => "json" },
      { :path => "/api/0.6/presets/1.json", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/presets/1.json", :method => :get },
      { :controller => "presets", :action => "show", :id => "1", :format => "json" }
    )
  end

  def test_create_success
    basic_authorization(users(:normal_user).email, "test")
    assert_difference('Preset.count') do
      post :create, { :json => "preset" }
    end

    assert_response :success
    #js = ActiveSupport::JSON.decode(@response.body)
    #assert_not_nil js
  end

  #test "should get index" do
  #  get :index
  #  assert_response :success
  #  assert_not_nil assigns(:presets)
  #end

  #test "should get new" do
  #  get :new
  #  assert_response :success
  #end


  #test "should show preset" do
  #  get :show, id: @preset
  #  assert_response :success
  #end

  #test "should get edit" do
  #  get :edit, id: @preset
  #  assert_response :success
  #end

  #test "should update preset" do
  #  patch :update, id: @preset, preset: { name: @preset.name, text: @preset.text }
  #  assert_redirected_to preset_path(assigns(:preset))
  #end

  #test "should destroy preset" do
  #  assert_difference('Preset.count', -1) do
  #    delete :destroy, id: @preset
  #  end
  #
  #  assert_redirected_to presets_path
  #end
end
