require "minitest"
require "minitest/autorun"
require "minitest/spec"
require "rack/test"

require "app"

describe "Paginated App" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def assert_all_returned(resp)
    parsed = JSON.parse(resp.body)
    assert_equal 99, parsed.size
    assert_match /my-app-001/i, resp.body
    assert_match /my-app-099/i, resp.body

    headers = resp.headers
    assert_equal "id 1..99", headers["Content-Range"]
    assert_equal "id ]99..; max=200", headers["Next-Range"]
  end

  it "returns all 99 w/o header" do
    get "/"

    assert_equal 200, last_response.status
    assert_all_returned(last_response)
  end

  it "returns all 99 with 'id ..' range" do
    get "/", {}, {'HTTP_RANGE' => 'id ..'}

    assert_equal 200, last_response.status
    assert_all_returned(last_response)
  end

  it "returns all 99 with 'id 1..' range" do
    get "/", {}, {'HTTP_RANGE' => 'id 1..'}

    assert_equal 200, last_response.status
    assert_all_returned(last_response)
  end

  it "returns all 99 with 'id [1..' range" do
    get "/", {}, {'HTTP_RANGE' => 'id [1..'}

    assert_equal 200, last_response.status
    assert_all_returned(last_response)
  end

  it "works with range 'id 1..5'" do
    get "/", {}, {'HTTP_RANGE' => 'id 1..5'}

    assert_equal 200, last_response.status

    headers = last_response.headers
    assert_equal "id 1..5", headers["Content-Range"]
    assert_equal "id ]5..; max=200", headers["Next-Range"]

    parsed = JSON.parse(last_response.body)
    assert_equal 5, parsed.size
    assert_match /my-app-001/i, last_response.body
    assert_match /my-app-005/i, last_response.body
  end

  it "works with range 'id ]5..'" do
    get "/", {}, {'HTTP_RANGE' => 'id ]5..'}

    assert_equal 200, last_response.status

    headers = last_response.headers
    assert_equal "id 6..99", headers["Content-Range"]
    assert_equal "id ]99..; max=200", headers["Next-Range"]

    parsed = JSON.parse(last_response.body)
    assert_equal 94, parsed.size
    assert_match /my-app-006/i, last_response.body
    assert_match /my-app-099/i, last_response.body
  end

  it "works with range 'id 1..; max=5'" do
    get "/", {}, {'HTTP_RANGE' => 'id 1..; max=5'}

    assert_equal 200, last_response.status

    headers = last_response.headers
    assert_equal "id 1..5", headers["Content-Range"]
    assert_equal "id ]5..; max=5", headers["Next-Range"]

    parsed = JSON.parse(last_response.body)
    assert_equal 5, parsed.size
    assert_match /my-app-001/i, last_response.body
    assert_match /my-app-005/i, last_response.body
  end

  it "works with range 'id 1..; order=desc'" do
    get "/", {}, {'HTTP_RANGE' => 'id 1..; order=desc'}

    assert_equal 200, last_response.status

    headers = last_response.headers
    assert_equal "id 1..99", headers["Content-Range"]
    assert_equal "id ]1..; max=200, order=desc", headers["Next-Range"]

    parsed = JSON.parse(last_response.body)
    assert_equal 99, parsed.size
    assert_match /my-app-001/i, last_response.body
    assert_match /my-app-099/i, last_response.body
  end

  it "works with range 'id ]5..10; max=5, order=desc'" do
    get "/", {}, {'HTTP_RANGE' => 'id ]5..10; max=5, order=desc'}

    assert_equal 200, last_response.status

    headers = last_response.headers
    assert_equal "id 6..10", headers["Content-Range"]
    assert_equal "id ]6..; max=5, order=desc", headers["Next-Range"]

    parsed = JSON.parse(last_response.body)
    assert_equal 5, parsed.size
    assert_match /my-app-006/i, last_response.body
    assert_match /my-app-010/i, last_response.body
  end

  it "works with range 'name ]my-app-001..my-app-999; max=10, order=asc'" do
    get "/", {}, {'HTTP_RANGE' => 'name ]my-app-001..my-app-999; max=10, order=asc'}

    assert_equal 200, last_response.status

    headers = last_response.headers
    assert_equal "name my-app-002..my-app-011", headers["Content-Range"]
    assert_equal "name ]my-app-011..; max=10", headers["Next-Range"]

    parsed = JSON.parse(last_response.body)
    assert_equal 10, parsed.size
    assert_match /my-app-002/i, last_response.body
    assert_match /my-app-011/i, last_response.body
  end
end
