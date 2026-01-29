# frozen_string_literal: true

# Tests for lib/tk/grid.rb (TkGrid module)
# Note: Tk.grid, Tk.grid_forget, Tk.ungrid are tested in test_tk_module.rb

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestGrid < Minitest::Test
  include TkTestHelper

  def test_tkgrid_configure
    assert_tk_app("TkGrid.configure", method(:app_tkgrid_configure))
  end

  def app_tkgrid_configure
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Label")
    btn = TkButton.new(root, text: "Button")

    # Basic configure
    TkGrid.configure(lbl, row: 0, column: 0)
    errors << "label not gridded" unless lbl.winfo_manager == "grid"

    # grid is alias for configure
    TkGrid.grid(btn, row: 1, column: 0)
    errors << "button not gridded" unless btn.winfo_manager == "grid"

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_configure_multiple_widgets
    assert_tk_app("TkGrid.configure multiple", method(:app_tkgrid_configure_multi))
  end

  def app_tkgrid_configure_multi
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl1 = TkLabel.new(root, text: "L1")
    lbl2 = TkLabel.new(root, text: "L2")
    lbl3 = TkLabel.new(root, text: "L3")

    # Configure multiple widgets in one row
    TkGrid.configure(lbl1, lbl2, lbl3)

    errors << "lbl1 not gridded" unless lbl1.winfo_manager == "grid"
    errors << "lbl2 not gridded" unless lbl2.winfo_manager == "grid"
    errors << "lbl3 not gridded" unless lbl3.winfo_manager == "grid"

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_configure_relative_placement
    assert_tk_app("TkGrid relative placement", method(:app_tkgrid_relative))
  end

  def app_tkgrid_relative
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl1 = TkLabel.new(root, text: "Spans")
    lbl2 = TkLabel.new(root, text: "Normal")

    # '-' increases columnspan
    TkGrid.configure(lbl1, '-', '-')  # spans 3 columns
    TkGrid.configure(lbl2)

    info1 = TkGrid.info(lbl1)
    errors << "expected columnspan 3, got #{info1['columnspan']}" unless info1['columnspan'] == 3

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_configure_empty_column
    assert_tk_app("TkGrid empty column", method(:app_tkgrid_empty_col))
  end

  def app_tkgrid_empty_col
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl1 = TkLabel.new(root, text: "Col0")
    lbl2 = TkLabel.new(root, text: "Col2")

    # 'x' leaves empty column
    TkGrid.configure(lbl1, 'x', lbl2)

    info1 = TkGrid.info(lbl1)
    info2 = TkGrid.info(lbl2)

    errors << "lbl1 should be in column 0" unless info1['column'] == 0
    errors << "lbl2 should be in column 2" unless info2['column'] == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_configure_no_widget_error
    assert_tk_app("TkGrid.configure no widget error", method(:app_tkgrid_no_widget))
  end

  def app_tkgrid_no_widget
    require 'tk'
    require 'tk/grid'

    errors = []

    begin
      TkGrid.configure()
      errors << "should raise ArgumentError for no widget"
    rescue ArgumentError => e
      errors << "wrong message" unless e.message == 'no widget is given'
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_add
    assert_tk_app("TkGrid.add", method(:app_tkgrid_add))
  end

  def app_tkgrid_add
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Added")
    TkGrid.add(lbl, row: 0, column: 0)

    errors << "label not gridded" unless lbl.winfo_manager == "grid"

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_info
    assert_tk_app("TkGrid.info", method(:app_tkgrid_info))
  end

  def app_tkgrid_info
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Info test")
    TkGrid.configure(lbl, row: 2, column: 3, sticky: 'nsew', padx: 5, pady: 10)

    info = TkGrid.info(lbl)

    errors << "expected row 2" unless info['row'] == 2
    errors << "expected column 3" unless info['column'] == 3
    # sticky can be returned in different orders (e.g., "nesw" vs "nsew")
    sticky = info['sticky'].to_s.chars.sort.join
    errors << "expected sticky nsew, got #{info['sticky']}" unless sticky == 'ensw'
    errors << "expected padx 5" unless info['padx'] == 5
    errors << "expected pady 10" unless info['pady'] == 10

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_forget
    assert_tk_app("TkGrid.forget", method(:app_tkgrid_forget))
  end

  def app_tkgrid_forget
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Forget me")
    TkGrid.configure(lbl, row: 0, column: 0)
    errors << "label should be gridded" unless lbl.winfo_manager == "grid"

    TkGrid.forget(lbl)
    errors << "label should be forgotten" unless lbl.winfo_manager == ""

    # forget with no args returns empty string
    result = TkGrid.forget
    errors << "forget with no args should return ''" unless result == ''

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_remove
    assert_tk_app("TkGrid.remove", method(:app_tkgrid_remove))
  end

  def app_tkgrid_remove
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Remove me")
    TkGrid.configure(lbl, row: 1, column: 2, sticky: 'ns')
    TkGrid.remove(lbl)

    errors << "label should be removed" unless lbl.winfo_manager == ""

    # remove with no args returns empty string
    result = TkGrid.remove
    errors << "remove with no args should return ''" unless result == ''

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_size
    assert_tk_app("TkGrid.size", method(:app_tkgrid_size))
  end

  def app_tkgrid_size
    require 'tk'
    require 'tk/grid'

    errors = []

    # Test on root - cleanup should have removed previous widgets
    # Empty grid
    size = TkGrid.size(root)
    errors << "empty grid should have 0 columns, got #{size[0]}" unless size[0] == 0
    errors << "empty grid should have 0 rows, got #{size[1]}" unless size[1] == 0

    # Add some widgets
    lbl1 = TkLabel.new(root, text: "L1")
    lbl2 = TkLabel.new(root, text: "L2")
    TkGrid.configure(lbl1, row: 0, column: 0)
    TkGrid.configure(lbl2, row: 1, column: 2)

    size = TkGrid.size(root)
    errors << "expected 3 columns, got #{size[0]}" unless size[0] == 3
    errors << "expected 2 rows, got #{size[1]}" unless size[1] == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_slaves
    assert_tk_app("TkGrid.slaves", method(:app_tkgrid_slaves))
  end

  def app_tkgrid_slaves
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl1 = TkLabel.new(root, text: "S1")
    lbl2 = TkLabel.new(root, text: "S2")
    lbl3 = TkLabel.new(root, text: "S3")

    TkGrid.configure(lbl1, row: 0, column: 0)
    TkGrid.configure(lbl2, row: 0, column: 1)
    TkGrid.configure(lbl3, row: 1, column: 0)

    # All slaves
    slaves = TkGrid.slaves(root)
    errors << "expected 3 slaves" unless slaves.size == 3

    # Slaves in row 0
    row0_slaves = TkGrid.slaves(root, row: 0)
    errors << "expected 2 slaves in row 0" unless row0_slaves.size == 2

    # Slaves in column 0
    col0_slaves = TkGrid.slaves(root, column: 0)
    errors << "expected 2 slaves in column 0" unless col0_slaves.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_bbox
    assert_tk_app("TkGrid.bbox", method(:app_tkgrid_bbox))
  end

  def app_tkgrid_bbox
    require 'tk'
    require 'tk/grid'

    errors = []
    root.deiconify

    lbl = TkLabel.new(root, text: "BBox test", width: 20)
    TkGrid.configure(lbl, row: 0, column: 0)
    Tk.update

    # Get bounding box of entire grid
    bbox = TkGrid.bbox(root)
    errors << "bbox should be array of 4" unless bbox.is_a?(Array) && bbox.size == 4

    # Get bounding box of specific cell
    cell_bbox = TkGrid.bbox(root, 0, 0)
    errors << "cell bbox should be array of 4" unless cell_bbox.is_a?(Array) && cell_bbox.size == 4

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_anchor
    assert_tk_app("TkGrid.anchor", method(:app_tkgrid_anchor))
  end

  def app_tkgrid_anchor
    require 'tk'
    require 'tk/grid'

    errors = []

    # Set anchor
    TkGrid.anchor(root, 'center')

    # Get anchor (returns the value)
    result = TkGrid.anchor(root)
    errors << "expected center, got #{result}" unless result == 'center'

    TkGrid.anchor(root, 'nw')
    result = TkGrid.anchor(root)
    errors << "expected nw, got #{result}" unless result == 'nw'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_location
    assert_tk_app("TkGrid.location", method(:app_tkgrid_location))
  end

  def app_tkgrid_location
    require 'tk'
    require 'tk/grid'

    errors = []
    root.deiconify

    lbl = TkLabel.new(root, text: "Location", width: 20, height: 2)
    TkGrid.configure(lbl, row: 0, column: 0)
    Tk.update

    # Get grid cell at coordinates
    loc = TkGrid.location(root, 5, 5)
    errors << "location should return [col, row] array" unless loc.is_a?(Array) && loc.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_propagate
    assert_tk_app("TkGrid.propagate", method(:app_tkgrid_propagate))
  end

  def app_tkgrid_propagate
    require 'tk'
    require 'tk/grid'

    errors = []

    # Default is true
    result = TkGrid.propagate(root)
    errors << "default propagate should be true" unless result == true

    # Disable propagate
    TkGrid.propagate(root, false)
    result = TkGrid.propagate(root)
    errors << "propagate should be false" unless result == false

    # Re-enable
    TkGrid.propagate(root, true)
    result = TkGrid.propagate(root)
    errors << "propagate should be true again" unless result == true

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_columnconfigure
    assert_tk_app("TkGrid.columnconfigure", method(:app_tkgrid_columnconfigure))
  end

  def app_tkgrid_columnconfigure
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Col config")
    TkGrid.configure(lbl, row: 0, column: 0)

    # Configure column
    TkGrid.columnconfigure(root, 0, weight: 1, minsize: 50, pad: 5)

    # Get column info
    info = TkGrid.columnconfiginfo(root, 0)
    errors << "expected weight 1" unless info['weight'] == 1
    errors << "expected minsize 50" unless info['minsize'] == 50
    errors << "expected pad 5" unless info['pad'] == 5

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_columnconfiginfo_slot
    assert_tk_app("TkGrid.columnconfiginfo slot", method(:app_tkgrid_colconfig_slot))
  end

  def app_tkgrid_colconfig_slot
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Col slot")
    TkGrid.configure(lbl, row: 0, column: 0)
    TkGrid.columnconfigure(root, 0, weight: 2, uniform: 'mygroup')

    # Get specific slot
    weight = TkGrid.columnconfiginfo(root, 0, :weight)
    errors << "expected weight 2, got #{weight}" unless weight == 2

    # uniform returns string
    uniform = TkGrid.columnconfiginfo(root, 0, :uniform)
    errors << "expected uniform 'mygroup'" unless uniform == 'mygroup'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_rowconfigure
    assert_tk_app("TkGrid.rowconfigure", method(:app_tkgrid_rowconfigure))
  end

  def app_tkgrid_rowconfigure
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Row config")
    TkGrid.configure(lbl, row: 0, column: 0)

    # Configure row
    TkGrid.rowconfigure(root, 0, weight: 3, minsize: 30, pad: 2)

    # Get row info
    info = TkGrid.rowconfiginfo(root, 0)
    errors << "expected weight 3" unless info['weight'] == 3
    errors << "expected minsize 30" unless info['minsize'] == 30
    errors << "expected pad 2" unless info['pad'] == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_rowconfiginfo_slot
    assert_tk_app("TkGrid.rowconfiginfo slot", method(:app_tkgrid_rowconfig_slot))
  end

  def app_tkgrid_rowconfig_slot
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Row slot")
    TkGrid.configure(lbl, row: 0, column: 0)
    TkGrid.rowconfigure(root, 0, weight: 4, uniform: 'rowgroup')

    # Get specific slot
    weight = TkGrid.rowconfiginfo(root, 0, :weight)
    errors << "expected weight 4, got #{weight}" unless weight == 4

    # uniform returns string
    uniform = TkGrid.rowconfiginfo(root, 0, :uniform)
    errors << "expected uniform 'rowgroup'" unless uniform == 'rowgroup'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_column_helper
    assert_tk_app("TkGrid.column", method(:app_tkgrid_column))
  end

  def app_tkgrid_column
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Column helper")
    TkGrid.configure(lbl, row: 0, column: 0)

    # column with hash = columnconfigure
    TkGrid.column(root, 0, weight: 5)

    # column without hash = columnconfiginfo
    info = TkGrid.column(root, 0)
    errors << "expected weight 5" unless info['weight'] == 5

    # column with slot = columnconfiginfo(slot)
    weight = TkGrid.column(root, 0, :weight)
    errors << "expected weight 5 from slot" unless weight == 5

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkgrid_row_helper
    assert_tk_app("TkGrid.row", method(:app_tkgrid_row))
  end

  def app_tkgrid_row
    require 'tk'
    require 'tk/grid'

    errors = []

    lbl = TkLabel.new(root, text: "Row helper")
    TkGrid.configure(lbl, row: 0, column: 0)

    # row with hash = rowconfigure
    TkGrid.row(root, 0, weight: 6)

    # row without hash = rowconfiginfo
    info = TkGrid.row(root, 0)
    errors << "expected weight 6" unless info['weight'] == 6

    # row with slot = rowconfiginfo(slot)
    weight = TkGrid.row(root, 0, :weight)
    errors << "expected weight 6 from slot" unless weight == 6

    raise errors.join("\n") unless errors.empty?
  end
end
