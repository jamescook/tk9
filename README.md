# tk-ng

Tk interface module for Ruby.

Fork of [ruby/tk](https://github.com/ruby/tk) with Tcl/Tk 8.6 and 9.x support. Modernized for Ruby 3.2+.

## Features

- Full Tcl/Tk 9.x compatibility
- Backward compatible with Tcl/Tk 8.6
- New Tcl 9 widget options (e.g., `placeholder` for Entry/Combobox)
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

## Documentation

### Read this first

If you want to use Ruby/Tk (tk.rb and so on), you must have tcltklib.so
which is working correctly. When you have some troubles on compiling,
please read [README.tcltklib] and [README.ActiveTcl].

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
[README.ActiveTcl]: README.ActiveTcl
[README.fork]: README.fork
[README.macosx-aqua]: README.macosx-aqua

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Contributions are welcome on GitHub at https://github.com/jamescook/tk-ng.

## License

The gem is available as open source under the terms of the [Ruby license](LICENSE.txt).

This is a fork of [ruby/tk](https://github.com/ruby/tk). Original authors: SHIBATA Hiroshi, Nobuyoshi Nakada, Jeremy Evans.
