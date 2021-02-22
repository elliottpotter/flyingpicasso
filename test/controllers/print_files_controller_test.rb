require 'test_helper'

class PrintFilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @print_file = print_files(:one)
  end

  test "should get index" do
    get print_files_url, as: :json
    assert_response :success
  end

  test "should create print_file" do
    assert_difference('PrintFile.count') do
      post print_files_url, params: { print_file: {  } }, as: :json
    end

    assert_response 201
  end

  test "should show print_file" do
    get print_file_url(@print_file), as: :json
    assert_response :success
  end

  test "should update print_file" do
    patch print_file_url(@print_file), params: { print_file: {  } }, as: :json
    assert_response 200
  end

  test "should destroy print_file" do
    assert_difference('PrintFile.count', -1) do
      delete print_file_url(@print_file), as: :json
    end

    assert_response 204
  end
end
