# tk-ng

Tk interface module for Ruby.

Fork of [ruby/tk](https://github.com/ruby/tk) with Tcl/Tk 8.6 and 9.x support. Modernized for Ruby 3.2+.

## Features

- Full Tcl/Tk 9.x compatibility
- Backward compatible with Tcl/Tk 8.6
- New Tcl 9 widget options (e.g., `placeholder` for Entry/Combobox)
- Background work API for responsive UIs (Thread/Ractor modes)
- Visual regression testing for both Tcl versions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tk-ng'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tk-ng

You may need to set options when using `gem install` so that the gem can find the Tcl/Tk headers and library:

    $ gem install tk-ng -- \
        --with-tcl-include='/path/to/tcl/header/directory' \
        --with-tk-include='/path/to/tk/header/directory' \
        --with-tcl-lib='/path/to/tcl/shared/library/directory' \
        --with-tk-lib='/path/to/tk/shared/library/directory'

## Usage

```ruby
require 'tk'

root = TkRoot.new { title "Hello, Tk9!" }
TkLabel.new(root) { text "Works with Tcl/Tk 8.6 and 9.x" }.pack
Tk.mainloop
```

Note: You still `require 'tk'` - the gem name is `tk-ng` but the library interface is unchanged.

## Background Work API

Tk applications need to keep the UI responsive while doing CPU-intensive work. The `TkCore.background_work` API provides a simple way to run work in threads or Ractors with automatic UI integration.

```ruby
require 'tk'

# Run work in background, stream results to UI
task = TkCore.background_work(files) do |t, data|
  data.each { |file| t.yield(process(file)) }
end.on_progress do |result|
  @log.insert(:end, "#{result}\n")
end.on_done do
  puts "Finished!"
end

# Control the task
task.pause   # Pause work (call t.check_pause in work block)
task.resume  # Resume paused work
task.stop    # Stop completely
```

**Important:** The work block runs in a background thread/Ractor and cannot access Tk directly. Use `t.yield()` to send results to `on_progress`, which runs on the main thread where Tk is available.

### Modes

Set the concurrency mode globally or per-task:

```ruby
# Global default (affects all subsequent background_work calls)
TkCore.background_work_mode = :thread   # Background thread (GVL-bound)
TkCore.background_work_mode = :ractor   # True parallelism (default)

# Per-task override
TkCore.background_work(data, mode: :thread) { |t, d| ... }
```

- **`:thread`** - Uses Ruby threads. Work shares the GVL with UI. Pause/resume always works.
- **`:ractor`** - Uses Ractors for true parallelism. [Data must be shareable](https://docs.ruby-lang.org/en/4.0/language/ractor_md.html#label-Shareable+procs). Best throughput on Ruby 4.x.

### Pause Support

For pause/resume to work, your work block must periodically check for pause requests:

```ruby
TkCore.background_work(items) do |t, data|
  data.each_slice(100) do |batch|
    t.check_pause  # Block here if paused
    batch.each { |item| t.yield(process(item)) }
  end
end
```

See [`sample/threading_demo.rb`](sample/threading_demo.rb) for a complete example comparing modes.

## Documentation

### Read this first

If you want to use Ruby/Tk (tk.rb and so on), you must have tcltklib.so
which is working correctly. When you have some troubles on compiling,
please read [README.tcltklib].

Even if there is a tcltklib.so on your Ruby library directory, it will not
work without Tcl/Tk libraries (e.g. libtcl9.0.so) on your environment.
You must also check that your Tcl/Tk is installed properly.

### Manual

- [Manual tcltklib](MANUAL_tcltklib.eng)

### Other documents

[README.tcltklib] for compilation instructions.

[README.fork] is a note on forking.

[README.macosx-aqua] is about MacOS X Aqua usage.

[README.tcltklib]: README.tcltklib
[README.fork]: README.fork
[README.macosx-aqua]: README.macosx-aqua

## Backwards Incompatible Changes

This fork removes legacy code that was complex, rarely used, or incompatible with modern systems.

### Removed Libraries

- **`multi-tk.rb`** - Removed. The ThreadGroup-based multi-interpreter dispatch (~3500 lines) added significant complexity. For multiple interpreters, use explicit calls: `interp.after(1000) { }` instead of relying on magic dispatch.

- **`remote-tk.rb`** - Removed. Depended on multi-tk.rb for controlling Tk interpreters in other processes.

- **`thread_tk.rb`** - Removed. Allowed running Tk mainloop on a background thread, which doesn't work on macOS (Tk requires the main thread).

- **`RUN_EVENTLOOP_ON_MAIN_THREAD`** - Removed. Tk now always runs on the main thread. The background thread machinery (~100 lines) that allowed running Tk in IRB on non-macOS has been removed. Run Tk code in scripts, not REPLs.

### Changed Behavior

- **`TkCore::INTERP`** - Deprecated. Accessing this constant emits a warning. Use `TkCore.interp` instead, which raises an error if multiple interpreters exist (preventing ambiguous "which interpreter?" bugs).

- **Encoding machinery** - Simplified. Modern Tcl (8.1+) and Ruby use UTF-8 natively, so the complex encoding conversion code was removed.

### Removed Methods

- **`TclTkIp#encoding_table`** - Removed. Raises `NotImplementedError` with explanation.

- **`TclTkIp#_make_menu_embeddable`** - Removed. This was a 2006-era workaround that accessed Tk's private internal structs. Use `TkMenubutton` for packable menu buttons.

### Removed: Japanized Tk Support

The `JAPANIZED_TK` constant and all related code has been removed. This was for a patched "Japanized Tcl/Tk" distribution (Tcl 7.6/Tk 4.2 - see `sample/demos-en/doc.org/README.JP`) that added a `kanji` command for Japanese text support before Tcl/Tk had proper Unicode handling.

Removed APIs:
- `Tk::JAPANIZED_TK` constant
- `Tk.show_kinsoku`, `Tk.add_kinsoku`, `Tk.delete_kinsoku` methods
- `latinfont`, `asciifont`, `kanjifont` pseudo-options
- `font_configure`, `latinfont_configure`, `kanjifont_configure` methods

Tcl 8.1 (April 1999) added native Unicode support ([Tcl chronology](https://wiki.tcl-lang.org/page/Tcl+chronology)). Use standard `font` options with UTF-8 strings.

### Modernized: TkFont Class

The original `TkFont` class (~2340 lines) has been replaced with a modern implementation (~200 lines) that creates named Tcl fonts.

```ruby
# Create fonts
font = TkFont.new('Helvetica 12 bold')
font = TkFont.new(family: 'Courier', size: 14)
label = TkLabel.new(root, font: font)

# Modify font - all widgets using it update automatically
font.family = 'Times'
font.size = 18

# Modify via widget accessor
label.font.family = 'Arial'

# Class methods
TkFont.families        # list available font families
TkFont.measure(font, text)  # measure text width in pixels
```

Named Tcl fonts propagate changes to all widgets using them, so changing `font.size = 24` updates every widget configured with that font.

**Not supported**: Features from the old TkFont like `TkNamedFont`, `latinfont`/`kanjifont` compound fonts, and `font_configure` methods have been removed.

### Deprecated Internal APIs

The `__*_optkeys` methods in `TkConfigMethod` are deprecated and will be removed:

- `__numval_optkeys`, `__boolval_optkeys`, `__strval_optkeys`, `__listval_optkeys`
- `__val2ruby_optkeys`, `__ruby2val_optkeys`
- `__tkvariable_optkeys`, `__font_optkeys`

**Migration**: Use the declarative `option` DSL instead:

```ruby
# Old way (deprecated)
class MyWidget < TkWindow
  def __boolval_optkeys
    super() + ['myoption']
  end
end

# New way
class MyWidget < TkWindow
  option :myoption, type: :boolean
end
```

The public API (`cget`, `configure`, `configinfo`) is unchanged.

### Removed: `TkItemConfigMethod` module

The `TkItemConfigMethod` module (from `lib/tk/itemconfig.rb`) has been removed. Its functionality has been merged into `Tk::ItemOptionDSL::InstanceMethods`, which is automatically included when you `extend Tk::ItemOptionDSL`.

If your code explicitly required `tk/itemconfig` or included `TkItemConfigMethod`, update it to use `Tk::ItemOptionDSL` instead. See `lib/tk/item_option_dsl.rb` for the replacement API.

### Removed: `__IGNORE_UNKNOWN_CONFIGURE_OPTION__`

The global flag `TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__` has been removed. This flag silently swallowed errors when `configure` or `cget` encountered unknown widget options - a design that hid bugs and made debugging difficult.

If you need to handle version-specific options, check the version explicitly:

```ruby
# Not recommended, but if you must:
begin
  widget.configure(maybe_invalid: value)
rescue TclTkLib::TclError
  # handle or ignore
end
```

### Removed: `GET_CONFIGINFO_AS_ARRAY` constant

The `TkComm::GET_CONFIGINFO_AS_ARRAY` and `TkComm::GET_CONFIGINFOwoRES_AS_ARRAY` constants have been removed. These controlled whether `configinfo` returned arrays or hashes - unnecessary complexity since arrays were the default and hash mode was rarely used.

`configinfo` now always returns arrays:
```ruby
widget.configinfo(:text)  # => ["text", "text", "Text", "", "Hello"]
widget.configinfo         # => [["text", ...], ["width", ...], ...]
```

Use `current_configinfo` for a hash of current values:
```ruby
widget.current_configinfo(:text)  # => {"text" => "Hello"}
widget.current_configinfo         # => {"text" => "Hello", "width" => 100, ...}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

Docker is the preferred way to run tests (avoids Tk windows popping up):

```bash
rake docker:test                              # Run tests in container
rake docker:test TEST=test/test_tk_font.rb    # Single file
rake docker:test:all                          # Full suite with extensions
```

For local testing:
```bash
rake test                                     # Runs with real Tk windows
```

### Tcl Version

Tests run against Tcl 9.0 by default. To test against 8.6:

```bash
TCL_VERSION=8.6 rake docker:test
```

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Contributions are welcome on GitHub at https://github.com/jamescook/tk-ng.

## License

The gem is available as open source under the terms of the [Ruby license](LICENSE.txt).

This is a fork of [ruby/tk](https://github.com/ruby/tk). Original authors: SHIBATA Hiroshi, Nobuyoshi Nakada, Jeremy Evans.
