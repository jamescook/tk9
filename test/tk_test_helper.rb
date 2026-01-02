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
require 'timeout'

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

  # Smoke test a sample file - checks it loads without crashing.
  #
  # Spawns the sample with TK_READY_FD env var pointing to a pipe.
  # Sample calls Tk.signal_ready when UI is loaded, which writes to the pipe.
  # Parent waits for signal, then sends SIGTERM for clean shutdown.
  #
  # Returns [success, stdout, stderr]
  #
  # Options:
  #   :timeout - max seconds to wait for ready signal (default: 10)
  #
  def smoke_test_sample(sample_path, timeout: 10, args: [])
    sample_path = File.expand_path(sample_path)
    raise ArgumentError, "Sample not found: #{sample_path}" unless File.exist?(sample_path)

    load_paths = $LOAD_PATH.select { |p| p.include?(File.dirname(__dir__)) }
    load_path_args = load_paths.flat_map { |p| ["-I", p] }

    # Create pipe for ready signal
    ready_r, ready_w = IO.pipe
    stdout_r, stdout_w = IO.pipe
    stderr_r, stderr_w = IO.pipe

    pid = Process.spawn(
      { 'TK_READY_FD' => '3' },
      RbConfig.ruby, *load_path_args, sample_path, *args,
      in: :close,
      out: stdout_w,
      err: stderr_w,
      3 => ready_w
    )

    # Parent closes write ends
    ready_w.close
    stdout_w.close
    stderr_w.close

    success = false
    stdout = ""
    stderr = ""

    # Hard timeout wrapper - ensures we never hang forever
    hard_timeout = timeout + 5

    begin
      Timeout.timeout(hard_timeout) do
        # Wait for ready signal or timeout
        timed_out = false
        if IO.select([ready_r], nil, nil, timeout)
          ready_r.read(1)  # Got ready signal - UI is up
          success = true
        else
          timed_out = true
        end
        ready_r.close

        # Send SIGTERM and wait for clean shutdown
        # (tcltk_compat.rb installs a handler that defers to Tk.root.destroy)
        if process_alive?(pid)
          Process.kill("TERM", pid)
          begin
            Timeout.timeout(2) { Process.wait(pid) }
          rescue Timeout::Error
            Process.kill("KILL", pid)
            Process.wait(pid)
          end
        else
          Process.wait(pid)
          success = false unless success
        end

        stdout = stdout_r.read
        stderr = stderr_r.read
        if timed_out
          stderr = "TIMEOUT: Sample did not signal ready within #{timeout}s\n#{stderr}"
        end
      end
    rescue Timeout::Error
      # Hard timeout hit - force kill and fail
      Process.kill("KILL", pid) rescue nil
      Process.wait(pid) rescue nil
      stdout = stdout_r.read rescue ""
      stderr = "HARD TIMEOUT: Sample did not respond within #{hard_timeout}s\n#{stderr_r.read rescue ""}"
      success = false
    ensure
      stdout_r.close unless stdout_r.closed?
      stderr_r.close unless stderr_r.closed?
    end

    [success, stdout, stderr]
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end

  # Assertion wrapper for smoke_test_sample
  def assert_sample_loads(sample_path, message: nil, timeout: 10)
    sample_name = File.basename(sample_path)
    message ||= "Sample #{sample_name} should load without crashing"

    success, stdout, stderr = smoke_test_sample(sample_path, timeout: timeout)

    output = []
    output << "STDOUT:\n#{stdout}" unless stdout.empty?
    output << "STDERR:\n#{stderr}" unless stderr.empty?

    assert success, "#{message}\n#{output.join("\n")}"
  end
end
