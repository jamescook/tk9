# frozen_string_literal: true

require 'method_source'

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
  # Project root for absolute paths in subprocesses
  PROJECT_ROOT = File.expand_path('..', __dir__)

  # Visual mode helper injected into subprocess code.
  # When VISUAL=1, shows the window and waits for user to close it.
  # Otherwise, destroys immediately for headless testing.
  #
  # Usage in test app methods:
  #   tk_end(root)  # instead of root.destroy
  #
  def self.visual_mode_preamble
    <<~RUBY
      def tk_end(root)
        if ENV['VISUAL']
          root.deiconify
          Tk.mainloop
        else
          root.destroy
        end
      end
    RUBY
  end

  # SimpleCov preamble injected into subprocess code for coverage merging
  # Only runs if ENV['COVERAGE'] is set
  #
  # Key optimization: subprocesses write individual result files and DON'T
  # merge with existing results. The main process collates all results at
  # the end. This avoids the O(n²) behavior of reading/writing a growing
  # resultset file after each subprocess.
  def self.simplecov_preamble
    <<~RUBY
      if ENV['COVERAGE']
        require 'simplecov'

        # Each subprocess gets its own directory to avoid file conflicts
        SimpleCov.coverage_dir "#{PROJECT_ROOT}/coverage/results/\#{Process.pid}"
        SimpleCov.command_name "subprocess:\#{Process.pid}"
        SimpleCov.print_error_status = false
        SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter

        SimpleCov.start do
          add_filter '/test/'
          add_filter '/ext/'
          add_filter '/benchmark/'
          track_files "#{PROJECT_ROOT}/lib/**/*.rb"
        end
      end
    RUBY
  end

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
  def tk_subprocess(code, coverage: true)
    # Build load path from current process
    load_paths = $LOAD_PATH.select { |p| p.include?(File.dirname(__dir__)) }
    load_path_args = load_paths.flat_map { |p| ["-I", p] }

    # Prepend SimpleCov setup for coverage merging
    full_code = coverage ? "#{TkTestHelper.simplecov_preamble}\n#{code}" : code

    # Pass env vars to subprocess
    env = {}
    env['VISUAL'] = '1' if ENV['VISUAL']
    env['COVERAGE'] = '1' if ENV['COVERAGE']

    stdout, stderr, status = Open3.capture3(
      env, RbConfig.ruby, *load_path_args, "-e", full_code
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
    caller_loc = caller_locations(1, 1).first
    warn "[DEPRECATION] assert_tk_test is deprecated. Use assert_tk_app instead. " \
         "Called from #{caller_loc.path}:#{caller_loc.lineno}"

    code = yield
    success, stdout, stderr, status = tk_subprocess(code)

    output = []
    output << "STDOUT:\n#{stdout}" unless stdout.empty?
    output << "STDERR:\n#{stderr}" unless stderr.empty?
    output << "Exit status: #{status.exitstatus}"

    assert success, "#{message}\n#{output.join("\n")}"
  end

  # Assertion wrapper that extracts source from a method and runs it.
  # This allows writing test code as regular Ruby methods with full
  # syntax highlighting and IDE support.
  #
  # Example:
  #   def test_something
  #     assert_tk_app("should do the thing", method(:my_app))
  #   end
  #
  #   def my_app
  #     require 'tk'
  #     root = TkRoot.new { withdraw }
  #     # test code with full syntax highlighting...
  #     root.destroy
  #   end
  #
  def assert_tk_app(message, app_method)
    # Extract method body (skip def line and closing end)
    source_lines = app_method.source.lines
    body = source_lines[1..-2].join

    # Prepend visual mode helper (defines tk_end)
    full_body = "#{TkTestHelper.visual_mode_preamble}\n#{body}"

    success, stdout, stderr, status = tk_subprocess(full_body)

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
