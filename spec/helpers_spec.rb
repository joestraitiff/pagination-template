require "minitest"
require "minitest/autorun"
require "minitest/spec"
require "rack/test"

require "app"

class TestHelper
  include Helpers
end

describe "Range header helpers" do
  let(:helpers) { TestHelper.new }

  it "#cast_type" do
    assert_equal 5, helpers.cast_type(:id, '5')
    assert_equal 5, helpers.cast_type(:id, 5)
    assert_equal 'bob', helpers.cast_type(:name, 'bob')
    assert_equal 5, helpers.cast_type(:name, 5)
  end

  it "#process_options" do
    assert_equal [200, :id, :asc], helpers.process_options(:id, nil)
    assert_equal [5, :id, :asc], helpers.process_options(:id, "max=5")
    assert_equal [10, Sequel.desc(:id), :desc], helpers.process_options(:id, "max=10, order=desc")
    assert_equal [200, Sequel.desc(:id), :desc], helpers.process_options(:id, "order=desc")
    assert_equal [12, Sequel.desc(:name), :desc], helpers.process_options(:name, "max=12, order=desc")
  end

  it "#process_range" do
    assert_equal nil, helpers.process_range(:id, "..")
    assert_equal ["? >= ?", :id, 1], helpers.process_range(:id, "1..")
    assert_equal ["? >= ?", :id, 1], helpers.process_range(:id, "[1..")
    assert_equal ["(? >= ?) AND (? <= ?)", :id, 1, :id, 5], helpers.process_range(:id, "1..5")
    assert_equal ["? > ?", :id, 5], helpers.process_range(:id, "]5..")
    assert_equal ["(? > ?) AND (? <= ?)", :id, 5, :id, 10], helpers.process_range(:id, "]5..10")
    assert_equal ["(? > ?) AND (? <= ?)", :id, 0, :id, 0], helpers.process_range(:id, "]my-app-001..my-app-999")
    assert_equal ["(? > ?) AND (? <= ?)", :name, "my-app-001", :name, "my-app-999"],
      helpers.process_range(:name, "]my-app-001..my-app-999")
  end

  it "#page_limits" do
    assert_equal({id: :id, where: nil, max: 200, order: :id, dir: :asc}, helpers.page_limits(nil))
    assert_equal({id: :id, where: nil, max: 200, order: :id, dir: :asc}, helpers.page_limits("id .."))
    assert_equal({id: :id, where: ["? >= ?", :id, 1], max: 200, order: :id, dir: :asc}, helpers.page_limits("id 1.."))
    assert_equal({id: :id, where: ["? >= ?", :id, 1], max: 200, order: :id, dir: :asc}, helpers.page_limits("id [1.."))
    assert_equal({id: :id, where: ["(? >= ?) AND (? <= ?)", :id, 1, :id, 5], max: 200,
      order: :id, dir: :asc}, helpers.page_limits("id 1..5"))
    assert_equal({id: :id, where: ["? > ?", :id, 5], max: 200, order: :id, dir: :asc}, helpers.page_limits("id ]5.."))
    assert_equal({id: :id, where: ["? >= ?", :id, 1], max: 5, order: :id, dir: :asc}, helpers.page_limits("id 1..; max=5"))
    assert_equal({id: :id, where: ["? >= ?", :id, 1], max: 200, order: Sequel.desc(:id), dir: :desc},
      helpers.page_limits("id 1..; order=desc"))
    assert_equal({id: :id, where: ["(? > ?) AND (? <= ?)", :id, 5, :id, 10], max: 5,
      order: Sequel.desc(:id), dir: :desc}, helpers.page_limits("id ]5..10; max=5, order=desc"))
    assert_equal({id: :name, where: ["(? > ?) AND (? <= ?)", :name, "my-app-001", :name, "my-app-999"],
      max: 10, order: :name, dir: :asc}, helpers.page_limits("name ]my-app-001..my-app-999; max=10, order=asc"))
  end
end
