# frozen_string_literal: true

# Helper for running Tk tests in isolated subprocesses.
#
# Why subprocesses? Tk's interpreter is a singleton - once you call
# root.destroy, the Tk application is terminated and cannot be recreated
# in the same process. This is by design in Tcl/Tk:
#
#   - Tk_Init can only be called once per interpreter
#   - Destroying "." terminates the Tk application
#   - There's no Tk_Reinit or way to recreate the main window
#
# See: https://www.tcl-lang.org/man/tcl8.5/TkLib/Tk_Init.htm
#      https://www.tcl-lang.org/man/tcl8.6/TkCmd/destroy.htm
#
# We spawn a fresh Ruby process for each test to get a clean Tk interpreter.

require 'open3'

module TkTestHelper
  # Runs Ruby code in a separate process with fresh Tk interpreter.
  # Returns [success, stdout, stderr, status]
  #
  # Example:
  #   success, out, err, status = tk_subprocess(<<~RUBY)
  #     require 'tk'
  #     root = TkRoot.new { withdraw }
  #     puts "it works"
  #     root.destroy
  #   RUBY
  #
  def tk_subprocess(code)
    # Build load path from current process
    load_paths = $LOAD_PATH.select { |p| p.include?(File.dirname(__dir__)) }
    load_path_args = load_paths.flat_map { |p| ["-I", p] }

    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby, *load_path_args, "-e", code
    )

    [status.success?, stdout, stderr, status]
  end

  # Assertion wrapper for tk_subprocess.
  # Fails the test with captured output if the subprocess fails.
  #
  # The block should return a string of Ruby code to execute.
  #
  # Example:
  #   def test_something
  #     assert_tk_test("should do the thing") do
  #       <<~RUBY
  #         require 'tk'
  #         root = TkRoot.new { withdraw }
  #         # test code...
  #         root.destroy
  #       RUBY
  #     end
  #   end
  #
  def assert_tk_test(message = "Tk subprocess test failed")
    code = yield
    success, stdout, stderr, status = tk_subprocess(code)

    output = []
    output << "STDOUT:\n#{stdout}" unless stdout.empty?
    output << "STDERR:\n#{stderr}" unless stderr.empty?
    output << "Exit status: #{status.exitstatus}"

    assert success, "#{message}\n#{output.join("\n")}"
  end
end
