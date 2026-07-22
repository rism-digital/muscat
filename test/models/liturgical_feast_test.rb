require 'test_helper'

class LiturgicalFeastTest < ActiveSupport::TestCase
  test "defaults to published on new records" do
    feast = LiturgicalFeast.new(name: "Adventus")

    assert_equal "published", feast.wf_stage
  end
end
