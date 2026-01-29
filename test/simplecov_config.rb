# frozen_string_literal: true

# Shared SimpleCov configuration for all test contexts:
# - Main test process (test_helper.rb)
# - TkWorker subprocess (tk_worker.rb)
# - Collation (Rakefile)
# - Subprocess preamble (tk_test_helper.rb)

module SimpleCovConfig
  PROJECT_ROOT = File.expand_path('..', __dir__)

  # Standard filters applied to all SimpleCov runs
  FILTERS = [
    '/test/',
    %r{^/ext/},
    '/benchmark/',
    '/lib/tk/demo_support.rb',
    '/lib/tcltk.rb'  # Deprecated stub, no code to cover
  ].freeze

  # Platform-specific filters
  def self.platform_filters
    filters = []
    # tk_mac.rb only works on macOS
    filters << '/lib/tk/tk_mac.rb' unless RUBY_PLATFORM =~ /darwin/
    filters
  end

  # Returns regex filter for generated files from non-current Tcl versions
  # e.g., if TCL_VERSION=9.0, filters out 8_6/, 8_5/, etc.
  def self.other_tcl_version_filter
    current = ENV.fetch('TCL_VERSION', '9.0').tr('.', '_')
    %r{/lib/tk/generated/(?!#{Regexp.escape(current)}/)}
  end

  # Apply standard SimpleCov configuration
  # Call this inside SimpleCov.start or SimpleCov.collate block
  def self.apply_filters(simplecov_context)
    FILTERS.each { |f| simplecov_context.add_filter(f) }
    simplecov_context.add_filter(other_tcl_version_filter)
    platform_filters.each { |f| simplecov_context.add_filter(f) }
  end

  # Standard groups for coverage report
  def self.apply_groups(simplecov_context)
    simplecov_context.add_group 'Core', 'lib/tk.rb'
    simplecov_context.add_group 'Widgets', 'lib/tk/'
    simplecov_context.add_group 'Tile (Ttk)', 'lib/tkextlib/tile/'
    simplecov_context.add_group 'BWidget', 'lib/tkextlib/bwidget/'
    simplecov_context.add_group 'TkImg', 'lib/tkextlib/tkimg/'
    simplecov_context.add_group 'TkDND', 'lib/tkextlib/tkDND/'
    simplecov_context.add_group 'Other Extensions', ->(src) {
      src.filename.include?('/lib/tkextlib/') &&
      !src.filename.include?('/tile/') &&
      !src.filename.include?('/bwidget/') &&
      !src.filename.include?('/tkimg/') &&
      !src.filename.include?('/tkDND/')
    }
    simplecov_context.add_group 'Utilities', ['lib/tkutil.rb', 'lib/tk/util.rb']
  end

  # Generate add_filter code lines from FILTERS array (for subprocess preamble)
  def self.filters_as_code
    lines = FILTERS.map do |f|
      case f
      when Regexp then "add_filter #{f.inspect}"
      when String then "add_filter '#{f}'"
      end
    end
    # Add platform-specific filters (evaluated at generation time)
    platform_filters.each do |f|
      lines << "add_filter '#{f}'"
    end
    lines.join("\n          ")
  end

  # Ruby code string for subprocess SimpleCov setup (used by tk_test_helper.rb)
  # This must be a string because it's eval'd in a separate process
  def self.subprocess_preamble(project_root: PROJECT_ROOT)
    <<~RUBY
      if ENV['COVERAGE']
        require 'simplecov'

        # Unique directory per subprocess to avoid write conflicts
        coverage_name = ENV['COVERAGE_NAME'] || 'default'
        SimpleCov.coverage_dir "#{project_root}/coverage/results/\#{coverage_name}_sub_\#{Process.pid}"
        SimpleCov.command_name "subprocess:\#{Process.pid}"
        SimpleCov.print_error_status = false
        SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter

        SimpleCov.start do
          #{filters_as_code}
          # Filter non-current Tcl version generated files
          current_tcl = ENV.fetch('TCL_VERSION', '9.0').tr('.', '_')
          add_filter %r{/lib/tk/generated/(?!\#{Regexp.escape(current_tcl)}/)}
          track_files "#{project_root}/lib/**/*.rb"
        end
      end
    RUBY
  end
end
