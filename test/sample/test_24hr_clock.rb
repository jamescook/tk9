# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class Test24hrClock < Minitest::Test
  include TkTestHelper

  def test_sample_loads_without_crashing
    assert_sample_loads(File.expand_path('../../sample/24hr_clock.rb', __dir__))
  end
end
