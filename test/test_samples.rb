# frozen_string_literal: true

# Smoke tests for sample scripts.
# Each sample that supports TK_READY_FD gets a test method here.
#
# To add a new sample test:
#   1. Add TK_READY_FD support to the sample (see existing samples for pattern)
#   2. Add a test method here

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestSamples < Minitest::Test
  include TkTestHelper

  SAMPLE_DIR = File.expand_path('../sample', __dir__)

  def test_24hr_clock
    assert_sample_loads("#{SAMPLE_DIR}/24hr_clock.rb")
  end

  def test_binding_demo
    assert_sample_loads("#{SAMPLE_DIR}/binding_demo.rb")
  end

  def test_binding_sample
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/binding_sample.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'button is clicked!!'
    assert_includes stdout, 'label is clicked!!'
  end

  def test_bindtag_sample
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/bindtag_sample.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'command of button-1'
    assert_includes stdout, 'command of button-2'
    assert_includes stdout, 'command of button-3'
    assert_includes stdout, 'command of button-4'
    assert_includes stdout, 'command of button-5'
    assert_includes stdout, 'call "set_class_bind"'
    assert_includes stdout, 'call Tk.callback_continue'
    assert_includes stdout, 'call Tk.callback_break'
    refute_includes stdout, 'never see this message'
  end

  def test_btn_with_frame
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/btn_with_frame.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
  end

  def test_cd_timer
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/cd_timer.rb", args: ["0.1"])

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'start clicked'
  end

  def test_editable_listbox
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/editable_listbox.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "lbox1 items: 14"
    assert_includes stdout, "lbox2 items: 14"
  end

  def test_figmemo_sample
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/figmemo_sample.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "canvas class: PhotoCanvas"
  end

  def test_menubar1
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/menubar1.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "Open clicked"
    assert_includes stdout, "Cut clicked"
    assert_includes stdout, "Copy clicked"
  end

  def test_multi_interp
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/multi_interp_test.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'Interpreter 1 created'
    assert_includes stdout, 'Interpreter 2 created'
    assert_includes stdout, 'Interpreter 3 created'
    assert_includes stdout, 'Created 3 interpreters'
    assert_includes stdout, 'Closing interpreter 1'
    assert_includes stdout, 'Closing interpreter 2'
    assert_includes stdout, 'Closing interpreter 3'
    assert_includes stdout, '=== Done! ==='
  end

  def test_tcltklib_sample0
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tcltklib/sample0.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'Two windows created'
    assert_includes stdout, 'Ruby says hello'
  end

  def test_tkhello
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkhello.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    # Button clicked twice
    assert_equal 2, stdout.scan(/^hello$/).size, "Expected 'hello' printed twice"
  end

  def test_tktimer
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tktimer.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'start clicked'
    assert_includes stdout, 'stop clicked'
  end

  def test_menubar2
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/menubar2.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "Open clicked"
    assert_includes stdout, "Cut clicked"
    assert_includes stdout, "Copy clicked"
  end

  def test_propagate
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/propagate.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "button 1 shown"
    assert_includes stdout, "button 2 shown"
    assert_includes stdout, "button 3 shown"
  end

  def test_tkdialog
    assert_sample_loads("#{SAMPLE_DIR}/tkdialog.rb")
  end

  def test_menubar3
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/menubar3.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "Open clicked"
    assert_includes stdout, "Cut clicked"
    assert_includes stdout, "Copy clicked"
  end

  def test_tktimer2
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tktimer2.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'timer running'
    assert_includes stdout, 'stop clicked'
    assert_includes stdout, 'restart clicked'
  end

  def test_tktimer3
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tktimer3.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'timer running'
    assert_includes stdout, 'stop clicked'
    assert_includes stdout, 'start clicked'
  end

  def test_optobj_sample
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/optobj_sample.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
    assert_includes stdout, 'toggled once'
    assert_includes stdout, 'toggled twice'
  end

  def test_tkalignbox
    assert_sample_loads("#{SAMPLE_DIR}/tkalignbox.rb")
  end

  def test_scrollframe
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/scrollframe.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
    assert_includes stdout, 'adding text widget'
    assert_includes stdout, 'vscroll off'
    assert_includes stdout, 'vscroll on'
  end

  def test_tkrttimer
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkrttimer.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'timers running'
    assert_includes stdout, 'stop clicked'
    assert_includes stdout, 'start clicked'
  end

  def test_tkballoonhelp
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkballoonhelp.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
  end

  def test_tkcombobox
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkcombobox.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
  end

  def test_tkline
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkline.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
    assert_includes stdout, 'line drawn'
  end

  def test_tkbrowse
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkbrowse.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
  end

  def test_tkfrom
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkfrom.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing 'UI loaded'\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'mail count: 5'
  end

  def test_tkmenubutton
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkmenubutton.rb")

    assert success, "Sample failed\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
  end

  def test_tkmsgcat_load_rb
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkmsgcat-load_rb.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'locales:'
  end

  def test_tkmsgcat_load_tk
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkmsgcat-load_tk.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'locales:'
  end

  def test_tkmulticolumnlist
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkmulticolumnlist.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'selected row'
  end

  def test_tkmultilistbox
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkmultilistbox.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'selected row'
  end

  def test_tkmultilistframe
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkmultilistframe.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'selected row'
  end

  def test_tkoptdb
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkoptdb.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
  end

  def test_tktextframe
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tktextframe.rb")

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded', "Missing UI loaded\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'vscroll'
  end

  def test_tkimg_demo
    success, stdout, stderr = smoke_test_sample("#{SAMPLE_DIR}/tkextlib/tkimg/demo.rb", timeout: 15)

    # Skip if tkimg extension not available
    if stderr.include?("can't find package Img") || stderr.include?("cannot find package Img")
      skip "tkimg extension not available"
    end

    assert success, "Sample failed\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'tkimg demo loaded', "Missing 'tkimg demo loaded'\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, 'loaded animated gif'
    assert_includes stdout, 'loaded gif gif87a'
    assert_includes stdout, 'loaded gif gif89a'
    assert_includes stdout, 'loaded bmp_1bit.bmp'
    assert_includes stdout, 'loaded png color'
    assert_includes stdout, 'loaded jpeg_color.jpg'
    assert_includes stdout, 'loaded tiff_lzw.tiff'
  end
end

# Separate test class for samples that test deprecated/removed features
class TestSamplesDeprecated < Minitest::Test
  include TkTestHelper

  SAMPLE_DIR = File.expand_path('../sample', __dir__)

  def test_cmd_resource_demo_raises_not_implemented
    sample_path = "#{SAMPLE_DIR}/cmd_resource_demo.rb"
    load_paths = $LOAD_PATH.select { |p| p.include?(File.dirname(__dir__)) }
    load_path_args = load_paths.flat_map { |p| ["-I", p] }

    _stdout, stderr, status = Open3.capture3(
      RbConfig.ruby, *load_path_args, sample_path
    )

    refute status.success?, "Sample should fail (new_proc_class removed)"
    assert_includes stderr, "new_proc_class removed"
    assert_includes stderr, "NotImplementedError"
    assert_includes stderr, "define procs in Ruby code"
  end
end
