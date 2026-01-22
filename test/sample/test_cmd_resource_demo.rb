# frozen_string_literal: true

# Test that removed TkOptionDB proc class methods raise helpful errors.
#
# The proc class feature (new_proc_class, etc.) has been removed because:
#   - It eval'd Ruby code from resource files (security risk)
#   - It relied on Ruby's $SAFE which was removed in Ruby 2.7
#
# This test documents the expected behavior when legacy code tries to
# use these methods - they should get a clear error with migration guidance.

require_relative '../test_helper'
require 'open3'
require_relative '../tk_test_helper'

class TestCmdResourceDemo < Minitest::Test
  include TkTestHelper

  def test_new_proc_class_raises_not_implemented
    sample_path = File.expand_path('../../sample/cmd_resource_demo.rb', __dir__)
    project_root = File.expand_path('../..', __dir__)
    load_paths = $LOAD_PATH.select { |p| p.include?(project_root) }
    load_path_args = load_paths.flat_map { |p| ["-I", p] }

    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby, *load_path_args, sample_path
    )

    # Should fail - new_proc_class is removed
    refute status.success?, "Sample should fail (new_proc_class removed)"

    # Should show helpful deprecation message
    assert_includes stderr, "new_proc_class removed"
    assert_includes stderr, "NotImplementedError"

    # Should mention migration path
    assert_includes stderr, "define procs in Ruby code"
  end
end
