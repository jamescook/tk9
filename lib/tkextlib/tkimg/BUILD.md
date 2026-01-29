# Building TkImg on macOS

TkImg is not available in Homebrew, so it must be built from source.

## Prerequisites

- Tcl/Tk 9.x from Homebrew: `brew install tcl-tk`
- libtommath: `brew install libtommath`

## Download

Download from SourceForge: https://sourceforge.net/projects/tkimg/files/tkimg/

Latest version: Img-2.1.0.tar.gz (as of January 2026)

## Build Steps

```bash
# Extract
tar xzf Img-2.1.0.tar.gz
cd Img-2.1.0

# Create build directory
mkdir build && cd build

# Configure with Homebrew Tcl/Tk paths
LDFLAGS="-L/opt/homebrew/opt/libtommath/lib" \
../configure \
  --with-tcl=/opt/homebrew/opt/tcl-tk/lib \
  --with-tk=/opt/homebrew/opt/tcl-tk/lib

# Build
make -j4

# Install (requires sudo for system-wide install)
sudo make install
```

## Testing the Build

Without installing system-wide, you can test by setting TCLLIBPATH:

```bash
# Point to the build directories
export TCLLIBPATH="/path/to/Img-2.1.0/build/png /path/to/Img-2.1.0/build/base /path/to/Img-2.1.0/build/zlib /path/to/Img-2.1.0/build/libpng"

# Test in Tcl
tclsh9.0 -c "package require img::png; puts [package require img::png]"

# Test in Ruby
bundle exec ruby -Ilib -e "require 'tk'; require 'tkextlib/tkimg/png'; puts Tk::Img::PNG.package_version"
```

## Ubuntu/Debian

On Ubuntu, TkImg is available as an apt package:

```bash
sudo apt-get install libtk-img
```

## Supported Formats

After installation, the following format handlers are available:
- BMP, GIF, ICO, JPEG, PCX, PNG, PPM, PS, RAW, SGI, SUN, TGA, TIFF, XBM, XPM
- Plus: DTED, FLIR, Pixmap, Window
