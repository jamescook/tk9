# frozen_string_literal: true

require_relative 'item_option_generator'

module Tk
  # Orchestrates item option generation for all widgets.
  # Called by `rake tk:generate_item_options`.
  #
  class ItemOptionGenerationService
    DEFAULT_OUTPUT_DIR = 'lib/tk/generated'

    # Widgets with item-level configuration
    ITEM_WIDGETS = {
      'Canvas'  => :canvas,
      'Menu'    => :menu,
      'Text'    => :text,
      'Listbox' => :listbox,
    }.freeze

    attr_reader :tcl_version, :generator, :output_dir

    def initialize(tcl_version:, output_dir: DEFAULT_OUTPUT_DIR)
      @tcl_version = tcl_version
      @output_dir = output_dir
      @generator = ItemOptionGenerator.new(tcl_version: tcl_version)
    end

    # Generate all item option files
    # @param output [IO] where to write progress (default: $stdout)
    # @return [Hash] results with :files and :loader_file keys
    def call(output: $stdout)
      version_dir = "#{output_dir}/#{tcl_version.gsub('.', '_')}"
      FileUtils.mkdir_p(version_dir)

      output.puts "Introspecting Tk item options for Tcl #{tcl_version}..."

      item_files = []
      ITEM_WIDGETS.each do |ruby_name, widget_key|
        output.print "  #{ruby_name} items..."
        begin
          entries = generator.introspect_widget_items(widget_key)
          filename = "#{ruby_name.downcase}_items"
          filepath = "#{version_dir}/#{filename}.rb"
          File.write(filepath, generator.generate_widget_file(ruby_name, entries))
          item_files << filename
          output.puts " #{entries.size} options -> #{filename}.rb"
        rescue => e
          output.puts " FAILED: #{e.message}"
        end
      end

      loader_file = write_loader_file(item_files)

      output.puts "\nGenerated #{item_files.size} item option files in #{version_dir}/"
      output.puts "Loader: #{loader_file}"

      { files: item_files, loader_file: loader_file }
    end

    private

    def write_loader_file(item_files)
      loader_content = <<~RUBY
        # frozen_string_literal: true
        # Auto-generated loader for Tcl/Tk #{tcl_version} item options
        # DO NOT EDIT - regenerate with: rake tk:generate_item_options

        #{item_files.map { |f| "require_relative '#{tcl_version.gsub('.', '_')}/#{f}'" }.join("\n")}
      RUBY
      loader_file = "#{output_dir}/item_options_#{tcl_version.gsub('.', '_')}.rb"
      File.write(loader_file, loader_content)
      loader_file
    end
  end
end
