require "test_helper"

class PortfolioControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get portfolio_index_url
    assert_response :success
  end

  test "should get create" do
    get portfolio_create_url
    assert_response :success
  end

  test "should get new" do
    get portfolio_new_url
    assert_response :success
  end

  test "should get show" do
    get portfolio_show_url
    assert_response :success
  end

  test "should get update" do
    get portfolio_update_url
    assert_response :success
  end

  test "should get edit" do
    get portfolio_edit_url
    assert_response :success
  end

  test "should get destroy" do
    get portfolio_destroy_url
    assert_response :success
  end
end
