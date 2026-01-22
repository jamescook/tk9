# frozen_string_literal: true

require_relative 'test_helper'
require 'tk'
require 'tk/item_option_generation_service'
require 'tmpdir'
require 'fileutils'

class TestItemOptionGenerationService < Minitest::Test
  # ===========================================
  # Constants and initialization
  # ===========================================

  def test_default_output_dir_constant
    assert_equal 'lib/tk/generated', Tk::ItemOptionGenerationService::DEFAULT_OUTPUT_DIR
  end

  def test_item_widgets_constant
    widgets = Tk::ItemOptionGenerationService::ITEM_WIDGETS
    assert_equal :canvas, widgets['Canvas']
    assert_equal :menu, widgets['Menu']
    assert_equal :text, widgets['Text']
    assert_equal :listbox, widgets['Listbox']
    assert_equal 4, widgets.size
  end

  def test_initialize_sets_tcl_version
    service = Tk::ItemOptionGenerationService.new(tcl_version: '9.0')
    assert_equal '9.0', service.tcl_version
  end

  def test_initialize_uses_default_output_dir
    service = Tk::ItemOptionGenerationService.new(tcl_version: '9.0')
    assert_equal 'lib/tk/generated', service.output_dir
  end

  def test_initialize_accepts_custom_output_dir
    service = Tk::ItemOptionGenerationService.new(tcl_version: '9.0', output_dir: '/tmp/custom')
    assert_equal '/tmp/custom', service.output_dir
  end

  def test_initialize_creates_generator
    service = Tk::ItemOptionGenerationService.new(tcl_version: '9.0')
    assert_instance_of Tk::ItemOptionGenerator, service.generator
    assert_equal '9.0', service.generator.tcl_version
  end

  # ===========================================
  # call - file generation
  # ===========================================

  def test_call_creates_version_directory
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: Tk::TCL_VERSION,
        output_dir: tmpdir
      )
      service.call(output: StringIO.new)

      version_dir = "#{tmpdir}/#{Tk::TCL_VERSION.gsub('.', '_')}"
      assert Dir.exist?(version_dir), "Expected version directory to be created"
    end
  end

  def test_call_generates_widget_files
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: Tk::TCL_VERSION,
        output_dir: tmpdir
      )
      result = service.call(output: StringIO.new)

      version_dir = "#{tmpdir}/#{Tk::TCL_VERSION.gsub('.', '_')}"

      # Should create files for each widget
      assert File.exist?("#{version_dir}/canvas_items.rb"), "Expected canvas_items.rb"
      assert File.exist?("#{version_dir}/menu_items.rb"), "Expected menu_items.rb"
      assert File.exist?("#{version_dir}/text_items.rb"), "Expected text_items.rb"
      assert File.exist?("#{version_dir}/listbox_items.rb"), "Expected listbox_items.rb"

      # Result should include file list
      assert_includes result[:files], 'canvas_items'
      assert_includes result[:files], 'menu_items'
      assert_includes result[:files], 'text_items'
      assert_includes result[:files], 'listbox_items'
    end
  end

  def test_call_generates_loader_file
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: '8.6',
        output_dir: tmpdir
      )
      result = service.call(output: StringIO.new)

      loader_file = "#{tmpdir}/item_options_8_6.rb"
      assert File.exist?(loader_file), "Expected loader file"

      content = File.read(loader_file)
      assert_includes content, "frozen_string_literal: true"
      assert_includes content, "Auto-generated loader for Tcl/Tk 8.6"
      assert_includes content, "require_relative '8_6/canvas_items'"
      assert_includes content, "require_relative '8_6/menu_items'"

      assert_equal loader_file, result[:loader_file]
    end
  end

  def test_call_writes_progress_to_output
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: Tk::TCL_VERSION,
        output_dir: tmpdir
      )
      output = StringIO.new
      service.call(output: output)

      progress = output.string
      assert_includes progress, "Introspecting Tk item options"
      assert_includes progress, "Canvas items"
      assert_includes progress, "Menu items"
      assert_includes progress, "Text items"
      assert_includes progress, "Listbox items"
      assert_includes progress, "Generated"
      assert_includes progress, "Loader:"
    end
  end

  # ===========================================
  # Generated file content
  # ===========================================

  def test_generated_canvas_file_has_valid_ruby
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: Tk::TCL_VERSION,
        output_dir: tmpdir
      )
      service.call(output: StringIO.new)

      version_dir = "#{tmpdir}/#{Tk::TCL_VERSION.gsub('.', '_')}"
      content = File.read("#{version_dir}/canvas_items.rb")

      # Should be valid Ruby (syntax check - will raise if invalid)
      RubyVM::InstructionSequence.compile(content)

      # Should contain expected structure
      assert_includes content, 'module CanvasItems'
      assert_includes content, 'item_option'
    end
  end

  # ===========================================
  # Error handling
  # ===========================================

  def test_call_continues_on_widget_introspection_failure
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: Tk::TCL_VERSION,
        output_dir: tmpdir
      )

      # Stub generator to fail on one widget
      def service.generator
        @stubbed_generator ||= begin
          gen = super
          def gen.introspect_widget_items(widget_key)
            raise "Simulated failure" if widget_key == :menu
            super
          end
          gen
        end
      end

      output = StringIO.new
      result = service.call(output: output)

      # Should continue processing other widgets
      assert_includes result[:files], 'canvas_items'
      assert_includes result[:files], 'text_items'
      assert_includes result[:files], 'listbox_items'
      refute_includes result[:files], 'menu_items'

      # Should log the failure
      assert_includes output.string, "FAILED"
    end
  end

  # ===========================================
  # Version string handling
  # ===========================================

  def test_version_with_dots_converted_to_underscores
    Dir.mktmpdir do |tmpdir|
      service = Tk::ItemOptionGenerationService.new(
        tcl_version: '9.0.1',
        output_dir: tmpdir
      )
      service.call(output: StringIO.new)

      assert Dir.exist?("#{tmpdir}/9_0_1"), "Should create dir with underscores"
      assert File.exist?("#{tmpdir}/item_options_9_0_1.rb"), "Loader should use underscores"
    end
  end
end
