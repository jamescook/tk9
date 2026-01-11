# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestTclTkLibSample0 < Minitest::Test
  include TkTestHelper

  # Tests sample/tcltklib/sample0.rb which demonstrates:
  #   - Multiple TclTkIp interpreters
  #   - TclTkLib.mainloop processing events for all interpreters
  #   - Ruby/Tcl interop via the 'ruby' command
  def test_sample_loads_with_multiple_interpreters
    sample_path = File.expand_path('../../sample/tcltklib/sample0.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDERR: #{stderr}"
    assert_includes stdout, 'Two windows created', "Should create two windows"
    assert_includes stdout, 'Ruby says hello', "Ruby->Tcl callback should work"
  end
end
