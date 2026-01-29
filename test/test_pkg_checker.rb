# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'tk_test_helper'

# NOTE: Just loads the script to exercise it and check code coverage.
# No idea if anyone needs this.

class TestPkgChecker < Minitest::Test
  include TkTestHelper

  def test_pkg_checker_runs
    assert_tk_subprocess("pkg_checker runs") do
      <<~RUBY
        ARGV.replace(['lib/tkextlib'])
        require 'tkextlib/pkg_checker'
      RUBY
    end
  end

  def test_pkg_checker_verbose
    assert_tk_subprocess("pkg_checker verbose") do
      <<~RUBY
        ARGV.replace(['-v', 'lib/tkextlib'])
        require 'tkextlib/pkg_checker'
      RUBY
    end
  end
end
