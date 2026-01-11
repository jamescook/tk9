# frozen_string_literal: false

require 'tk'
require 'tkextlib/tile'
require 'fileutils'

module VisualRegression
  # A comprehensive Tk/Ttk widget showcase for visual regression testing.
  # Displays all major widgets in static states across multiple tabs,
  # then captures screenshots of each tab (with optional state changes like scrolling).
  class WidgetShowcase
    attr_reader :output_dir, :tcl_version, :tk_version

    def initialize(output_dir:)
      @output_dir = output_dir
      @tcl_version = Tk::TCL_VERSION rescue "unknown"
      @tk_version = Tk::TK_VERSION rescue "unknown"
      @scrollable_widgets = {}  # Store references for scroll state captures
      FileUtils.mkdir_p(output_dir)
    end

    def run
      setup_error_handler
      build_ui
      schedule_captures
      Tk.mainloop
    end

    def setup_error_handler
      # Define bgerror handler to catch background errors from Tk.after callbacks.
      # When errors occur in Tk.after callbacks, Tcl saves the error and invokes
      # bgerror as an idle event. We define it to print the error and exit.
      Tk.tk_call('proc', '::bgerror', 'message', <<~'TCL')
        puts stderr "ERROR (bgerror): $message"
        puts stderr [info errorinfo]
        flush stderr
        exit 1
      TCL
    end

    private

    # Captures define what screenshots to take. Each can specify:
    # - tab_index: which notebook tab to select
    # - name: screenshot filename (without .png)
    # - setup: optional proc to run before capture (e.g., scroll)
    def captures
      [
        { tab_index: 0, name: '01_basic' },
        { tab_index: 1, name: '02_selection' },
        { tab_index: 2, name: '03_range' },
        { tab_index: 3, name: '04_text_canvas' },
        { tab_index: 4, name: '05_treeview' },
        { tab_index: 5, name: '06_panes_frames' },
        { tab_index: 6, name: '07_scrolling_top' },
        { tab_index: 6, name: '07_scrolling_bottom', setup: -> { scroll_to_bottom } },
        { tab_index: 7, name: '08_menus_misc' },
        { tab_index: 8, name: '09_i18n' },
      ]
    end

    def build_ui
      @root = TkRoot.new { title "Tk Widget Showcase" }
      @root.geometry("850x550+100+100")

      @root.raise
      @root.focus(true)
      @root.overrideredirect(true)  # Borderless window - must be after focus for some reason. Needed to avoid subtle changes between runs due to rounded corners

      # Track OS-level window focus for screenshot warnings
      @window_focused = true
      Tk.tk_call('bind', @root, '<Activate>', proc { @window_focused = true })
      Tk.tk_call('bind', @root, '<Deactivate>', proc { @window_focused = false })

      # Force light appearance to avoid dark mode variations
      if RUBY_PLATFORM =~ /darwin/
        Tk.tk_call('tk::unsupported::MacWindowStyle', 'appearance', @root, 'aqua')
      end

      # Add a menubar to the root window
      build_menubar

      Ttk::Label.new(@root, text: "Tk/Ttk Widget Showcase (#{@tk_version})", font: 'Helvetica 14 bold').pack(pady: 10)

      @notebook = Ttk::Notebook.new(@root)
      @notebook.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      build_basic_tab           # 0
      build_selection_tab       # 1
      build_range_tab           # 2
      build_text_canvas_tab     # 3
      build_treeview_tab        # 4
      build_panes_frames_tab    # 5
      build_scrolling_tab       # 6
      build_menus_misc_tab      # 7
      build_i18n_tab            # 8
    end

    def build_menubar
      menubar = TkMenu.new(@root)
      @root.menu(menubar)

      # File menu
      file_menu = TkMenu.new(menubar, tearoff: false)
      menubar.add('cascade', menu: file_menu, label: 'File')
      file_menu.add('command', label: 'New')
      file_menu.add('command', label: 'Open...')
      file_menu.add('command', label: 'Save')
      file_menu.add('separator')
      file_menu.add('command', label: 'Exit')

      # Edit menu
      edit_menu = TkMenu.new(menubar, tearoff: false)
      menubar.add('cascade', menu: edit_menu, label: 'Edit')
      edit_menu.add('command', label: 'Undo')
      edit_menu.add('command', label: 'Redo')
      edit_menu.add('separator')
      edit_menu.add('command', label: 'Cut')
      edit_menu.add('command', label: 'Copy')
      edit_menu.add('command', label: 'Paste')

      # Help menu
      help_menu = TkMenu.new(menubar, tearoff: false)
      menubar.add('cascade', menu: help_menu, label: 'Help')
      help_menu.add('command', label: 'About')
    end

    ###########################################
    # Tab 0: Basic Widgets
    ###########################################
    def build_basic_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Basic')

      # Labels section
      lf = Ttk::Labelframe.new(tab, text: 'Labels')
      lf.pack(fill: 'x', padx: 10, pady: 5)

      label_frame = Ttk::Frame.new(lf)
      label_frame.pack(fill: 'x', padx: 5, pady: 5)

      TkLabel.new(label_frame) { text 'Classic TkLabel' }.pack(side: 'left', padx: 5)
      Ttk::Label.new(label_frame) { text 'Ttk::Label' }.pack(side: 'left', padx: 5)
      Ttk::Label.new(label_frame, relief: 'sunken', padding: 3) { text 'Sunken' }.pack(side: 'left', padx: 5)

      # TkMessage - auto-wrapping label
      lf_msg = Ttk::Labelframe.new(tab, text: 'TkMessage (auto-wrap)')
      lf_msg.pack(fill: 'x', padx: 10, pady: 5)
      TkMessage.new(lf_msg, width: 400) {
        text 'TkMessage automatically wraps text to fit within its width. This is useful for longer text that needs to flow naturally.'
      }.pack(padx: 5, pady: 5, anchor: 'w')

      # Buttons section
      lf = Ttk::Labelframe.new(tab, text: 'Buttons')
      lf.pack(fill: 'x', padx: 10, pady: 5)
      frame = Ttk::Frame.new(lf)
      frame.pack(fill: 'x', padx: 5, pady: 5)

      TkButton.new(frame) { text 'TkButton' }.pack(side: 'left', padx: 2)
      Ttk::Button.new(frame) { text 'Ttk::Button' }.pack(side: 'left', padx: 2)
      Ttk::Button.new(frame, state: 'disabled') { text 'Disabled' }.pack(side: 'left', padx: 2)

      # Entries section
      lf = Ttk::Labelframe.new(tab, text: 'Entry Widgets')
      lf.pack(fill: 'x', padx: 10, pady: 5)
      frame = Ttk::Frame.new(lf)
      frame.pack(fill: 'x', padx: 5, pady: 5)

      e1 = TkEntry.new(frame, width: 20)
      e1.pack(side: 'left', padx: 2)
      e1.insert(0, 'TkEntry')

      e2 = Ttk::Entry.new(frame, width: 20)
      e2.pack(side: 'left', padx: 2)
      e2.insert(0, 'Ttk::Entry')

      e3 = Ttk::Entry.new(frame, width: 15)
      e3.pack(side: 'left', padx: 2)
      e3.insert(0, 'Disabled')
      e3.state(['disabled'])

      e4 = Ttk::Entry.new(frame, width: 15)
      e4.pack(side: 'left', padx: 2)
      e4.insert(0, 'Readonly')
      e4.state(['readonly'])

      # Placeholder (Tcl/Tk 9.0+ only)
      frame2 = Ttk::Frame.new(lf)
      frame2.pack(fill: 'x', padx: 5, pady: 5)

      entry_opts = { width: 25 }
      entry_opts[:placeholder] = 'Enter your name...' if Tk::TK_MAJOR_VERSION >= 9
      e5 = Ttk::Entry.new(frame2, entry_opts)
      e5.pack(side: 'left', padx: 2)

      combo_opts = { width: 20, values: ['Red', 'Green', 'Blue'] }
      combo_opts[:placeholder] = 'Select a color...' if Tk::TK_MAJOR_VERSION >= 9
      e6 = Ttk::Combobox.new(frame2, combo_opts)
      e6.pack(side: 'left', padx: 2)
    end

    ###########################################
    # Tab 1: Selection Widgets
    ###########################################
    def build_selection_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Selection')

      container = Ttk::Frame.new(tab)
      container.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      # Checkbuttons
      lf = Ttk::Labelframe.new(container, text: 'Checkbuttons')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      check_var1 = TkVariable.new(1)
      check_var2 = TkVariable.new(0)
      check_var3 = TkVariable.new(1)

      TkCheckbutton.new(lf, variable: check_var1) { text 'TkCheckbutton (on)' }.pack(anchor: 'w', padx: 5)
      Ttk::Checkbutton.new(lf, text: 'Ttk (off)', variable: check_var2).pack(anchor: 'w', padx: 5)
      Ttk::Checkbutton.new(lf, text: 'Ttk (on)', variable: check_var3).pack(anchor: 'w', padx: 5)
      Ttk::Checkbutton.new(lf, text: 'Disabled', state: 'disabled').pack(anchor: 'w', padx: 5)

      # Radiobuttons
      lf = Ttk::Labelframe.new(container, text: 'Radiobuttons')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      radio_var = TkVariable.new('opt2')

      TkRadiobutton.new(lf, variable: radio_var, value: 'opt1') { text 'TkRadiobutton' }.pack(anchor: 'w', padx: 5)
      Ttk::Radiobutton.new(lf, text: 'Ttk Selected', variable: radio_var, value: 'opt2').pack(anchor: 'w', padx: 5)
      Ttk::Radiobutton.new(lf, text: 'Ttk Unselected', variable: radio_var, value: 'opt3').pack(anchor: 'w', padx: 5)

      # List widgets
      lf = Ttk::Labelframe.new(container, text: 'List Widgets')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      combo_var = TkVariable.new('Option B')
      Ttk::Combobox.new(lf, textvariable: combo_var,
                        values: ['Option A', 'Option B', 'Option C'],
                        state: 'readonly', width: 15).pack(padx: 5, pady: 5)

      # OptionMenu
      opt_var = TkVariable.new('Choice 2')
      TkOptionMenubutton.new(lf, opt_var, 'Choice 1', 'Choice 2', 'Choice 3').pack(padx: 5, pady: 5)

      listbox = TkListbox.new(lf, height: 3, width: 16)
      listbox.pack(padx: 5, pady: 5)
      ['Item One', 'Item Two', 'Item Three'].each { |item| listbox.insert('end', item) }
      listbox.selection_set(1)
    end

    ###########################################
    # Tab 2: Range/Numeric Widgets
    ###########################################
    def build_range_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Range')

      # Scales
      lf = Ttk::Labelframe.new(tab, text: 'Scale Widgets')
      lf.pack(fill: 'x', padx: 10, pady: 5)
      frame = Ttk::Frame.new(lf)
      frame.pack(fill: 'x', padx: 5, pady: 5)

      scale1 = TkScale.new(frame, orient: 'horizontal', from: 0, to: 100, length: 150, label: 'TkScale')
      scale1.set(35)
      scale1.pack(side: 'left', padx: 10)

      scale2 = Ttk::Scale.new(frame, orient: 'horizontal', from: 0, to: 100, length: 150)
      scale2.set(65)
      scale2.pack(side: 'left', padx: 10)

      scale3 = TkScale.new(frame, orient: 'vertical', from: 0, to: 100, length: 80)
      scale3.set(50)
      scale3.pack(side: 'left', padx: 10)

      # Spinboxes
      lf = Ttk::Labelframe.new(tab, text: 'Spinbox Widgets')
      lf.pack(fill: 'x', padx: 10, pady: 5)
      frame = Ttk::Frame.new(lf)
      frame.pack(fill: 'x', padx: 5, pady: 5)

      spin1 = TkSpinbox.new(frame, from: 0, to: 100, width: 10)
      spin1.set(42)
      spin1.pack(side: 'left', padx: 5)

      spin2 = Ttk::Spinbox.new(frame, from: 0, to: 100, width: 10)
      spin2.set(25)
      spin2.pack(side: 'left', padx: 5)

      Ttk::Spinbox.new(frame, values: ['Small', 'Medium', 'Large'], width: 10).pack(side: 'left', padx: 5)

      # Progress bars
      lf = Ttk::Labelframe.new(tab, text: 'Progress Bars')
      lf.pack(fill: 'x', padx: 10, pady: 5)
      frame = Ttk::Frame.new(lf)
      frame.pack(fill: 'x', padx: 5, pady: 5)

      Ttk::Label.new(frame, text: '0%:').pack(side: 'left', padx: 5)
      Ttk::Progressbar.new(frame, orient: 'horizontal', length: 100, mode: 'determinate', value: 0).pack(side: 'left', padx: 5)

      Ttk::Label.new(frame, text: '50%:').pack(side: 'left', padx: 5)
      Ttk::Progressbar.new(frame, orient: 'horizontal', length: 100, mode: 'determinate', value: 50).pack(side: 'left', padx: 5)

      Ttk::Label.new(frame, text: '100%:').pack(side: 'left', padx: 5)
      Ttk::Progressbar.new(frame, orient: 'horizontal', length: 100, mode: 'determinate', value: 100).pack(side: 'left', padx: 5)
    end

    ###########################################
    # Tab 3: Text and Canvas
    ###########################################
    def build_text_canvas_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Text/Canvas')

      container = Ttk::Frame.new(tab)
      container.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      # Text widget (basic, no scrollbar - scrolling tab has scrolled version)
      lf = Ttk::Labelframe.new(container, text: 'TkText')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      text = TkText.new(lf, width: 28, height: 10, wrap: 'word')
      text.pack(fill: 'both', expand: true, padx: 5, pady: 5)
      text.insert('end', "TkText widget.\n\n")
      text.insert('end', "Supports multiple lines,\n")
      text.insert('end', "word wrapping, and\n")
      text.insert('end', "text formatting.\n\n")
      text.insert('end', "Tcl #{@tcl_version} / Tk #{@tk_version}")

      # Canvas widget
      lf = Ttk::Labelframe.new(container, text: 'TkCanvas')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      canvas = TkCanvas.new(lf, width: 240, height: 180, bg: 'white')
      canvas.pack(fill: 'both', expand: true, padx: 5, pady: 5)

      # Create shapes and exercise TkcTagAccess methods
      rect = TkcRectangle.new(canvas, 15, 15, 80, 55, fill: 'lightblue', outline: 'blue', width: 2)
      oval = TkcOval.new(canvas, 100, 15, 180, 55, fill: 'lightgreen', outline: 'green', width: 2)
      TkcLine.new(canvas, 15, 70, 220, 70, fill: 'red', width: 2, arrow: 'last')
      TkcPolygon.new(canvas, 50, 85, 15, 130, 85, 130, fill: 'yellow', outline: 'orange', width: 2)
      TkcArc.new(canvas, 110, 80, 180, 135, start: 0, extent: 270, fill: 'lightpink', outline: 'purple', width: 2)
      TkcText.new(canvas, 120, 155, text: 'Canvas Shapes', font: 'Helvetica 9')

      # Exercise TkcTag and TkcTagAccess (from canvastag.rb)
      group = TkcGroup.new(canvas, rect, oval)
      group.gettags
      rect.bbox
    end

    ###########################################
    # Tab 4: Treeview
    ###########################################
    def build_treeview_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Treeview')

      lf = Ttk::Labelframe.new(tab, text: 'Ttk::Treeview')
      lf.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      tree = Ttk::Treeview.new(lf, columns: ['size', 'modified'], height: 12)
      tree.pack(fill: 'both', expand: true, padx: 5, pady: 5)

      tree.heading_configure('#0', text: 'Name')
      tree.heading_configure('size', text: 'Size')
      tree.heading_configure('modified', text: 'Modified')
      tree.column_configure('#0', width: 250)
      tree.column_configure('size', width: 100)
      tree.column_configure('modified', width: 120)

      # Populate with sample data
      folder1 = tree.insert('', 'end', text: 'Documents', values: ['--', '2024-01-15'])
      tree.insert(folder1, 'end', text: 'report.pdf', values: ['2.4 MB', '2024-01-10'])
      tree.insert(folder1, 'end', text: 'notes.txt', values: ['12 KB', '2024-01-14'])
      tree.insert(folder1, 'end', text: 'presentation.pptx', values: ['5.1 MB', '2024-01-13'])

      folder2 = tree.insert('', 'end', text: 'Images', values: ['--', '2024-01-12'])
      tree.insert(folder2, 'end', text: 'photo.jpg', values: ['4.1 MB', '2024-01-11'])
      tree.insert(folder2, 'end', text: 'icon.png', values: ['24 KB', '2024-01-12'])

      folder3 = tree.insert('', 'end', text: 'Source', values: ['--', '2024-01-16'])
      tree.insert(folder3, 'end', text: 'main.rb', values: ['8 KB', '2024-01-16'])
      tree.insert(folder3, 'end', text: 'helper.rb', values: ['3 KB', '2024-01-15'])

      tree.insert('', 'end', text: 'README.md', values: ['2 KB', '2024-01-15'])

      folder1.open
      folder3.open
    end

    ###########################################
    # Tab 5: Panes and Frames
    ###########################################
    def build_panes_frames_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Panes/Frames')

      # Panedwindow
      lf = Ttk::Labelframe.new(tab, text: 'Ttk::Panedwindow')
      lf.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      paned = Ttk::Panedwindow.new(lf, orient: 'horizontal')
      paned.pack(fill: 'both', expand: true, padx: 5, pady: 5)

      left_pane = Ttk::Frame.new(paned, width: 150, height: 100)
      Ttk::Label.new(left_pane, text: 'Left Pane', anchor: 'center').pack(expand: true)
      paned.add(left_pane, weight: 1)

      right_pane = Ttk::Frame.new(paned, width: 150, height: 100)
      Ttk::Label.new(right_pane, text: 'Right Pane', anchor: 'center').pack(expand: true)
      paned.add(right_pane, weight: 1)

      # Frame relief styles
      lf = Ttk::Labelframe.new(tab, text: 'Frame Relief Styles')
      lf.pack(fill: 'x', padx: 10, pady: 5)

      relief_frame = Ttk::Frame.new(lf)
      relief_frame.pack(fill: 'x', padx: 5, pady: 5)

      %w[flat raised sunken groove ridge solid].each do |relief|
        f = TkFrame.new(relief_frame, relief: relief, borderwidth: 2, width: 80, height: 40)
        f.pack(side: 'left', padx: 5, pady: 5)
        f.pack_propagate(false)
        TkLabel.new(f, text: relief).pack(expand: true)
      end

      # LabelFrame comparison
      lf2 = Ttk::Labelframe.new(tab, text: 'LabelFrame Variants')
      lf2.pack(fill: 'x', padx: 10, pady: 5)

      lf_container = Ttk::Frame.new(lf2)
      lf_container.pack(fill: 'x', padx: 5, pady: 5)

      classic_lf = TkLabelFrame.new(lf_container, text: 'TkLabelFrame')
      classic_lf.pack(side: 'left', padx: 10, pady: 5, fill: 'both', expand: true)
      TkLabel.new(classic_lf, text: 'Classic').pack(padx: 10, pady: 10)

      ttk_lf = Ttk::Labelframe.new(lf_container, text: 'Ttk::Labelframe')
      ttk_lf.pack(side: 'left', padx: 10, pady: 5, fill: 'both', expand: true)
      Ttk::Label.new(ttk_lf, text: 'Themed').pack(padx: 10, pady: 10)
    end

    ###########################################
    # Tab 6: Scrolling Widgets
    ###########################################
    def build_scrolling_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Scrolling')

      container = Ttk::Frame.new(tab)
      container.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      # Scrolled Text
      lf = Ttk::Labelframe.new(container, text: 'Scrolled TkText')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      text_frame = Ttk::Frame.new(lf)
      text_frame.pack(fill: 'both', expand: true, padx: 5, pady: 5)

      @scrollable_widgets[:text] = TkText.new(text_frame, width: 25, height: 12, wrap: 'word')
      scrollbar_t = Ttk::Scrollbar.new(text_frame, orient: 'vertical')
      @scrollable_widgets[:text].yscrollbar(scrollbar_t)

      @scrollable_widgets[:text].pack(side: 'left', fill: 'both', expand: true)
      scrollbar_t.pack(side: 'right', fill: 'y')

      # Add content
      30.times do |i|
        @scrollable_widgets[:text].insert('end', "Line #{i + 1}: Sample scrollable text content.\n")
      end

      # Scrolled Listbox
      lf = Ttk::Labelframe.new(container, text: 'Scrolled TkListbox')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      list_frame = Ttk::Frame.new(lf)
      list_frame.pack(fill: 'both', expand: true, padx: 5, pady: 5)

      @scrollable_widgets[:listbox] = TkListbox.new(list_frame, height: 12, width: 20)
      scrollbar_l = Ttk::Scrollbar.new(list_frame, orient: 'vertical')
      @scrollable_widgets[:listbox].yscrollbar(scrollbar_l)

      @scrollable_widgets[:listbox].pack(side: 'left', fill: 'both', expand: true)
      scrollbar_l.pack(side: 'right', fill: 'y')

      # Add content
      30.times do |i|
        @scrollable_widgets[:listbox].insert('end', "List Item #{i + 1}")
      end
      @scrollable_widgets[:listbox].selection_set(0)

      # Standalone scrollbars demo
      lf = Ttk::Labelframe.new(container, text: 'Scrollbars')
      lf.pack(side: 'left', fill: 'both', padx: 5)

      sb_frame = Ttk::Frame.new(lf)
      sb_frame.pack(fill: 'both', expand: true, padx: 5, pady: 5)

      TkScrollbar.new(sb_frame, orient: 'vertical').pack(side: 'left', fill: 'y', padx: 2)
      Ttk::Scrollbar.new(sb_frame, orient: 'vertical').pack(side: 'left', fill: 'y', padx: 2)
      TkScrollbar.new(sb_frame, orient: 'horizontal').pack(side: 'bottom', fill: 'x', pady: 2)
    end

    def scroll_to_bottom
      @scrollable_widgets[:text]&.see('end')
      @scrollable_widgets[:listbox]&.see('end')
      @scrollable_widgets[:listbox]&.selection_clear(0, 'end')
      @scrollable_widgets[:listbox]&.selection_set('end')
    end

    ###########################################
    # Tab 7: Menus and Misc
    ###########################################
    def build_menus_misc_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'Menus/Misc')

      # Note about menubar
      lf = Ttk::Labelframe.new(tab, text: 'Menubar')
      lf.pack(fill: 'x', padx: 10, pady: 5)
      Ttk::Label.new(lf, text: '↑ See menubar at top of window (File, Edit, Help)').pack(padx: 5, pady: 10)

      container = Ttk::Frame.new(tab)
      container.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      # Menubutton
      lf = Ttk::Labelframe.new(container, text: 'Menubuttons')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      mb1 = Ttk::Menubutton.new(lf, text: 'Ttk::Menubutton')
      menu1 = TkMenu.new(mb1, tearoff: false)
      menu1.add('command', label: 'Option 1')
      menu1.add('command', label: 'Option 2')
      menu1.add('separator')
      menu1.add('command', label: 'Option 3')
      mb1.menu(menu1)
      mb1.pack(padx: 5, pady: 5, anchor: 'w')

      mb2 = TkMenubutton.new(lf, text: 'TkMenubutton', relief: 'raised')
      menu2 = TkMenu.new(mb2, tearoff: false)
      menu2.add('command', label: 'Action A')
      menu2.add('command', label: 'Action B')
      mb2.menu(menu2)
      mb2.pack(padx: 5, pady: 5, anchor: 'w')

      # Separators
      lf = Ttk::Labelframe.new(container, text: 'Separators')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      Ttk::Label.new(lf, text: 'Horizontal:').pack(anchor: 'w', padx: 5, pady: 2)
      Ttk::Separator.new(lf, orient: 'horizontal').pack(fill: 'x', padx: 5, pady: 5)
      Ttk::Label.new(lf, text: 'Content below').pack(anchor: 'w', padx: 5, pady: 2)

      sep_frame = Ttk::Frame.new(lf)
      sep_frame.pack(fill: 'x', padx: 5, pady: 5)
      Ttk::Label.new(sep_frame, text: 'Left').pack(side: 'left')
      Ttk::Separator.new(sep_frame, orient: 'vertical').pack(side: 'left', fill: 'y', padx: 10)
      Ttk::Label.new(sep_frame, text: 'Right').pack(side: 'left')

      # Sizegrip
      lf = Ttk::Labelframe.new(container, text: 'Sizegrip')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      grip_frame = Ttk::Frame.new(lf)
      grip_frame.pack(fill: 'both', expand: true, padx: 5, pady: 5)
      Ttk::Label.new(grip_frame, text: '(corner grip →)').pack(expand: true)
      Ttk::Sizegrip.new(grip_frame).pack(side: 'right', anchor: 'se')
    end

    ###########################################
    # Tab 8: Internationalization / Encoding
    ###########################################
    def build_i18n_tab
      tab = Ttk::Frame.new(@notebook)
      @notebook.add(tab, text: 'i18n')

      container = Ttk::Frame.new(tab)
      container.pack(fill: 'both', expand: true, padx: 10, pady: 5)

      # CJK Languages
      lf = Ttk::Labelframe.new(container, text: 'CJK (Chinese/Japanese/Korean)')
      lf.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      # Japanese
      Ttk::Label.new(lf, text: '日本語:').pack(anchor: 'w', padx: 5)
      Ttk::Label.new(lf, text: '  ひらがな カタカナ 漢字').pack(anchor: 'w', padx: 10)
      Ttk::Label.new(lf, text: '  こんにちは世界').pack(anchor: 'w', padx: 10)

      # Chinese
      Ttk::Label.new(lf, text: '中文:').pack(anchor: 'w', padx: 5, pady: [5, 0])
      Ttk::Label.new(lf, text: '  简体中文 繁體中文').pack(anchor: 'w', padx: 10)
      Ttk::Label.new(lf, text: '  你好世界').pack(anchor: 'w', padx: 10)

      # Korean
      Ttk::Label.new(lf, text: '한국어:').pack(anchor: 'w', padx: 5, pady: [5, 0])
      Ttk::Label.new(lf, text: '  안녕하세요 세계').pack(anchor: 'w', padx: 10)

      # Other scripts and symbols
      lf2 = Ttk::Labelframe.new(container, text: 'Other Scripts & Symbols')
      lf2.pack(side: 'left', fill: 'both', expand: true, padx: 5)

      # Cyrillic
      Ttk::Label.new(lf2, text: 'Кириллица: Привет мир').pack(anchor: 'w', padx: 5)

      # Greek
      Ttk::Label.new(lf2, text: 'Ελληνικά: Γειά σου κόσμε').pack(anchor: 'w', padx: 5, pady: [5, 0])

      # Arabic (RTL)
      Ttk::Label.new(lf2, text: 'العربية: مرحبا بالعالم').pack(anchor: 'w', padx: 5, pady: [5, 0])

      # Hebrew (RTL)
      Ttk::Label.new(lf2, text: 'עברית: שלום עולם').pack(anchor: 'w', padx: 5, pady: [5, 0])

      # Emoji
      Ttk::Label.new(lf2, text: 'Emoji: 🎉 🚀 ❤️ 🌍 ☀️ 🎸').pack(anchor: 'w', padx: 5, pady: [10, 0])

      # Math/symbols
      Ttk::Label.new(lf2, text: 'Math: ∑ ∏ √ ∞ ≠ ≤ ≥ ± ×').pack(anchor: 'w', padx: 5, pady: [5, 0])

      # Currency
      Ttk::Label.new(lf2, text: 'Currency: $ € £ ¥ ₹ ₽ ฿').pack(anchor: 'w', padx: 5, pady: [5, 0])

      # Entry widget with i18n text
      lf3 = Ttk::Labelframe.new(tab, text: 'Entry with Unicode')
      lf3.pack(fill: 'x', padx: 10, pady: 5)

      entry_frame = Ttk::Frame.new(lf3)
      entry_frame.pack(fill: 'x', padx: 5, pady: 5)

      e1 = Ttk::Entry.new(entry_frame, width: 30)
      e1.pack(side: 'left', padx: 2)
      e1.insert(0, '日本語テスト 🎌')

      e2 = Ttk::Entry.new(entry_frame, width: 30)
      e2.pack(side: 'left', padx: 2)
      e2.insert(0, 'Ελληνικά → العربية')
    end

    ###########################################
    # Screenshot Capture
    ###########################################
    def schedule_captures
      # Wait for window to be ready before capturing screenshots.
      # Using a fixed delay since winfo ismapped doesn't work reliably under xvfb.
      Tk.after(1000) { run_captures(0) }
    end

    def run_captures(index)
      capture_list = captures
      if index < capture_list.length
        capture = capture_list[index]

        # Select the tab
        @notebook.select(capture[:tab_index])

        # Wait for render
        Tk.after(500) do
          # Run optional setup (e.g., scroll to bottom)
          capture[:setup]&.call

          # Wait for setup to take effect
          Tk.after(200) do
            take_screenshot(capture[:name])
            Tk.after(300) { run_captures(index + 1) }
          end
        end
      else
        puts "Screenshots saved to: #{output_dir}/"
        Tk.after(500) { @root.destroy }
      end
    end

    def take_screenshot(name)
      # Try to ensure window is frontmost
      @root.raise
      Tk.update

      # Abort if window doesn't have focus (screenshots will capture wrong content)
      if RUBY_PLATFORM =~ /darwin/ && !ENV['CI'] && !@window_focused
        warn ""
        warn "ERROR: Tk window is not focused! Screenshots would capture wrong content."
        warn "       Keep the widget showcase window focused during capture."
        warn ""
        @root.destroy
        exit 1
      end

      x = @root.winfo_rootx
      y = @root.winfo_rooty
      w = @root.winfo_width
      h = @root.winfo_height

      # No title bar adjustment needed - window is borderless (overrideredirect)

      file = File.join(output_dir, "#{name}.png")
      capture_screen_region(x, y, w, h, file)
      puts "  Captured: #{name}.png"
    end

    # Cross-platform screen capture.
    #
    # macOS: Uses screencapture. Requires Screen Recording permission for your
    # terminal app (System Settings > Privacy & Security > Screen Recording).
    # First run will prompt for permission - grant it and restart terminal.
    #
    # Linux: Uses ImageMagick's import command. Requires imagemagick package.
    # For headless CI, run under xvfb-run.
    def capture_screen_region(x, y, w, h, file)
      $stderr.puts "  DEBUG: capture_screen_region(#{x}, #{y}, #{w}, #{h}, #{file})"
      $stderr.flush

      if RUBY_PLATFORM =~ /darwin/
        success = system("screencapture", "-R#{x},#{y},#{w},#{h}", file)
      else
        cmd = "import -window root -crop #{w}x#{h}+#{x}+#{y} +repage #{file}"
        $stderr.puts "  DEBUG: running: #{cmd}"
        $stderr.flush
        output = `#{cmd} 2>&1`
        success = $?.success?
        unless success
          $stderr.puts "  DEBUG: import failed with status #{$?.exitstatus}: #{output}"
          $stderr.flush
        end
      end

      unless success && File.exist?(file)
        msg = "Screenshot capture failed: #{file}"
        $stderr.puts "ERROR: #{msg}"
        $stderr.flush
        @root.destroy
        exit 1
      end
    end
  end
end

# Allow running standalone
if __FILE__ == $0
  output_dir = ARGV[0] || 'screenshots/unverified'
  VisualRegression::WidgetShowcase.new(output_dir: output_dir).run
end
