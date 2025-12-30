# Testing

## Visual Regression Testing

The test suite includes visual regression tests that capture screenshots of a widget showcase and compare them against blessed baselines. This ensures UI consistency across Tcl/Tk versions and platforms.

### Directory Structure

```
screenshots/
├── blessed/           # Committed baseline images
│   ├── darwin/
│   │   ├── tcl8.6/
│   │   └── tcl9.0/
│   └── linux/
│       ├── tcl8.6/
│       └── tcl9.0/
├── unverified/        # Generated during test runs (gitignored)
└── diffs/             # Diff images for failures (gitignored)
```

**Note:** Windows is not yet tested. Contributions welcome!

### Running Tests

```bash
# Run full test suite (includes visual regression)
rake test

# Generate screenshots without comparison
rake screenshots:generate
```

### Blessing Screenshots

When screenshots change intentionally (new widgets, style updates, etc.), you need to update the baselines:

```bash
# Bless all platforms
rake screenshots:bless

# Bless specific platform
rake screenshots:bless:darwin
rake screenshots:bless:linux
rake screenshots:bless:windows
```

### macOS (Darwin)

Prerequisites:
- Grant Screen Recording permission to your terminal app (System Settings > Privacy & Security > Screen Recording)

```bash
# Compile for Tcl/Tk 9.0
rake clean && rake compile -- --with-tcltkversion=9.0 \
  --with-tcl-lib=$(brew --prefix tcl-tk)/lib \
  --with-tcl-include=$(brew --prefix tcl-tk)/include/tcl-tk \
  --with-tk-lib=$(brew --prefix tcl-tk)/lib \
  --with-tk-include=$(brew --prefix tcl-tk)/include/tcl-tk \
  --without-X11

# Run tests
rake test

# Bless if needed
rake screenshots:bless:darwin
```

For Tcl/Tk 8.6:
```bash
rake clean && rake compile -- --with-tcltkversion=8.6 \
  --with-tcl-lib=$(brew --prefix tcl-tk@8)/lib \
  --with-tcl-include=$(brew --prefix tcl-tk@8)/include \
  --with-tk-lib=$(brew --prefix tcl-tk@8)/lib \
  --with-tk-include=$(brew --prefix tcl-tk@8)/include \
  --without-X11
```

### Linux (via Docker)

For generating Linux screenshots from any platform:

```bash
# Build and run both Tcl 8.6 and 9.0
./scripts/linux-screenshots.sh

# Or manually:

# Tcl/Tk 9.0 (built from source)
docker build -f Dockerfile.ci-test -t tk-ci-test-9 .
docker run --rm -v $(pwd)/screenshots:/app/screenshots tk-ci-test-9

# Tcl/Tk 8.6 (from apt)
docker build -f Dockerfile.ci-test --build-arg TCL_VERSION=8.6 -t tk-ci-test-8 .
docker run --rm -v $(pwd)/screenshots:/app/screenshots tk-ci-test-8

# Bless the generated screenshots
rake screenshots:bless:linux
```

### How It Works

1. `WidgetShowcase` creates a window with tabs showing all major Tk/Ttk widgets
2. Screenshots are captured using platform-specific tools:
   - macOS: `screencapture`
   - Linux: ImageMagick `import` (under Xvfb)
3. `Perceptualdiff` compares against blessed baselines
4. Tests fail if pixel differences exceed threshold (default: 100 pixels)

### Troubleshooting

**macOS: Black or missing screenshots**
- Grant Screen Recording permission to Terminal/iTerm
- Restart your terminal after granting permission

**Linux: No display**
- Run under Xvfb: `xvfb-run rake test`
- Or use the Docker workflow above

**Tests fail with "Missing blessed baselines"**
- Run `rake screenshots:bless` to create initial baselines
- Commit the new baseline images

**Tests fail with pixel differences**
- Check `screenshots/diffs/` for visual diff images
- If changes are intentional, re-bless the screenshots
- If unintentional, investigate the rendering difference
