# frozen_string_literal: true

# Common test helper - loads SimpleCov for coverage, then minitest.
# All test files should require this FIRST.
#
# Set COVERAGE=1 to enable coverage collection.

if ENV['COVERAGE']
  require 'simplecov'

  # Unique command name for each process (enables subprocess merging)
  SimpleCov.command_name "test:#{Process.pid}"

  SimpleCov.start do
    add_filter '/test/'
    add_filter '/ext/'
    add_filter '/benchmark/'

    add_group 'Core', 'lib/tk.rb'
    add_group 'Widgets', 'lib/tk'
    add_group 'Extensions', 'lib/tkextlib'
    add_group 'Utilities', ['lib/tkutil.rb', 'lib/tk/util.rb']

    # Track all lib files
    track_files 'lib/**/*.rb'
  end
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'

# Collate subprocess coverage results at the very end (after all tests complete)
if ENV['COVERAGE']
  Minitest.after_run do
    # Find all per-subprocess result files (each in its own pid directory)
    subprocess_results = Dir["coverage/results/*/.resultset.json"]
    if subprocess_results.any?
      SimpleCov.collate(subprocess_results) do
        add_filter '/test/'
        add_filter '/ext/'
        add_filter '/benchmark/'

        add_group 'Core', 'lib/tk.rb'
        add_group 'Widgets', 'lib/tk'
        add_group 'Extensions', 'lib/tkextlib'
        add_group 'Utilities', ['lib/tkutil.rb', 'lib/tk/util.rb']
      end
    end
  end
end
