# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestMultiInterpSample < Minitest::Test
  include TkTestHelper

  # Tests sample/multi_interp_test.rb which demonstrates:
  #   - Multiple Tk::Bridge instances (each wrapping independent TclTkIp)
  #   - Polling event loop with DONT_WAIT for multi-interpreter support
  #   - Isolated state per interpreter (separate click counters)
  def test_multi_interpreter_sample
    sample_path = File.expand_path('../../sample/multi_interp_test.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should run without crashing\nSTDERR: #{stderr}"

    # All 3 interpreters should be created
    assert_includes stdout, 'Interpreter 1 created'
    assert_includes stdout, 'Interpreter 2 created'
    assert_includes stdout, 'Interpreter 3 created'
    assert_includes stdout, 'Created 3 interpreters'

    # Close callbacks should fire for each window
    assert_includes stdout, 'Closing interpreter 1'
    assert_includes stdout, 'Closing interpreter 2'
    assert_includes stdout, 'Closing interpreter 3'

    # Should complete successfully
    assert_includes stdout, '=== Done! ==='
  end
end
