# trofs - Tcl Read-Only Filesystem

**Upstream**: https://math.nist.gov/~DPorter/tcltk/trofs/

**Version**: 0.4.9 (vendored and patched for Tcl 8.6+ and Tcl 9.0 compatibility)

## What is trofs?

trofs is a Tcl extension that provides a read-only virtual filesystem. It allows
you to package files into a `.trofs` archive and mount them as a virtual
directory that Tcl can read from transparently.

This is useful for:
- Packaging application resources (images, scripts, data files)
- Creating self-contained Tcl applications
- Distributing read-only data with your application

## Why is this vendored?

The upstream trofs 0.4.9 only supports Tcl 8.x. This vendored copy has been
patched to support both Tcl 8.6+ and Tcl 9.0+ using the standard TEA build
system with minimal changes.

> **Note**: This is a proof-of-concept for getting trofs working with Tcl 9.
> The patches are functional but have not been reviewed by the Tcl community
> or the original author. Use at your own discretion. If you need production
> use of trofs, consider contributing these patches upstream or consulting
> with the Tcl community for best practices.

### Patches from upstream:

**configure** - Version check fixes:
- Accept Tcl 8.4+ or Tcl 9+ (was: reject if not Tcl 8)
- Fix conditional logic for Tcl 9 (minor version checks)

**Makefile.in** - pkgIndex.tcl generation:
- Fixed broken version check that rejected Tcl 9
- Uses `package vsatisfies 8.6-9.1` range check

**generic/tcl9compat.h** - New compatibility header:
- `Tcl_Size` typedef for older Tcl
- Channel version macros for Tcl 8 vs 9

**generic/trofs.c** - Tcl 9 API compatibility:
- `#if TCL_MAJOR_VERSION >= 9` guards for channel driver changes
- `close2Proc` vs `closeProc`, `wideSeekProc` vs `seekProc`
- `Tcl_Size` vs `int` for size parameters

**library/procs.tcl** - Tcl 9 compatibility:
- Changed `-encoding binary` to `-translation binary`

## Building

Uses standard TEA (Tcl Extension Architecture) build system.

From the tk-ng root directory:

```bash
# Build trofs
rake compile:trofs

# Clean build artifacts
rake trofs:clean

# Full clean (including configure-generated files)
rake trofs:distclean

# Run Tcl tests
rake trofs:test

# Run Ruby integration tests (requires main tk extension compiled)
rake trofs:test:ruby
```

The built library is placed in `ext/trofs/libtrofs0.4.9.dylib` (or `.so` on Linux).

### Manual Build

```bash
cd ext/trofs
./configure --with-tcl=/path/to/tcl/lib
make
make install  # optional
```

## Usage from Tcl

```tcl
# Add the build directory to the package search path
lappend auto_path /path/to/ext/trofs

# Set library path for development (not needed after make install)
set env(TROFS_LIBRARY) /path/to/ext/trofs/library

# Load the extension
package require trofs 0.4.9

# Create an archive
trofs::archive /path/to/source/directory mydata.trofs

# Mount the archive
trofs::mount mydata.trofs /virtual/path

# Access files through the virtual path
set data [read [open /virtual/path/somefile.txt]]

# Unmount when done
trofs::unmount /virtual/path
```

## Usage from Ruby/Tk

```ruby
require 'tk'

# Ensure trofs library is in Tcl's search path
trofs_dir = File.expand_path('ext/trofs', __dir__)
Tk.tk_call('lappend', 'auto_path', trofs_dir)
ENV['TROFS_LIBRARY'] = File.join(trofs_dir, 'library')

# Load the package
TkPackage.require('trofs', '0.4.9')

# Use trofs commands
Tk.tk_call('trofs::archive', '/path/to/source', 'mydata.trofs')
Tk.tk_call('trofs::mount', 'mydata.trofs', '/virtual/path')
```

## Commands

- `trofs::archive source_directory archive_file` - Create a `.trofs` archive
- `trofs::mount archive_file mount_point` - Mount an archive at a virtual path
- `trofs::unmount mount_point` - Unmount a previously mounted archive

## Tests

All tests are in `tests/`:
- `test_trofs.tcl` - Tcl tests for the patched version
- `test_trofs.rb` - Ruby integration tests
- `upstream/` - Original upstream tcltest-based tests (reference only, may not work)

## License

trofs is released under the Tcl license. See `license.terms` for details.

## Original Author

Don Porter (NIST)
