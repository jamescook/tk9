#!/usr/bin/env ruby
# frozen_string_literal: false
# tk-record: screen_size=900x600, name=tkimg_demo
#
#  Tk::Img demo
#
#    --  This script is based on demo.tcl of Tcl/Tk's 'Img' extension.
#        Image data in this script is those of demo.tcl.
#        Please read 'license_terms_of_Img_extension' file.
#
require 'tk'
require 'tkextlib/tkimg'
require 'tkextlib/tkimg/ps'  # Required for PostScript/PDF format support

#
# Make the Image format available.
#
class TkImg_demo
  def initialize
    img_version = Tk::Img.package_version

    @typeFrame = Hash.new
    @imgPriv = Hash.new

    root = TkRoot.new(:title=>'Tests for available image formats')

    root.winfo_children.each{|w| w.destroy}
    TkImage.names{|img| img.delete}

    f = TkFrame.new
    TkButton.new(f, :text=>'Dismiss', :command=>proc{exit}).pack(:side=>:left)
    f.pack(:side=>:top, :expand=>:y, :fill=>:both)

    TkMessage.new(:aspect=>900, :text=>format('This page shows the available image formats of the Img extension (Img version %s, using Tcl/Tk %s)', img_version, Tk::TK_PATCHLEVEL)).pack(:side=>:top, :expand=>:y, :fill=>:both)
  end

##############################

  def update_animated_gif(w, method, num)
    return unless @imgPriv[w]

    if @imgPriv[w][:args]
      im = TkPhotoImage.new
      im.copy(@imgPriv[w][num])
      num += 1
      begin
        im.configure(@imgPriv[w][:args].merge(:format=>[:gif, {:index=>num}]))
        im.configure(:data=>'', :file=>'') #free storage
        @imgPriv[w][num] = im
      rescue
        @imgPriv[w].delete(:args)
        if num > 1
          num = 0
          im = @imgPriv[w][num]
        else
          # this is not an animated GIF; just stop
          @imgPriv[w].delete(0)
          return
        end
      end
    else
      num += 1
      num = 0 unless @imgPriv[w][num]
      im = @imgPriv[w][num]
    end
    begin
      w.__send__(method, im)
      Tk.update_idletasks
      Tk.after(20, proc{update_animated_gif(w, method, num)})
    rescue
      @imgPriv[w].delete(:args)
      @imgPriv[w].each{|im|
        @im.delete
        @imgPriv.delete(im)
      }
    end
  end

  def show_animated_gif(keys)
    w = TkLabel.new
    begin
      im = TkPhotoImage.new(keys.merge(:format=>[:gif, {:index=>0}]))
      im.configure(:data=>'', :file=>'', :format=>'') #free storage
      w.image(im)
      @imgPriv[w] ||= Hash.new
      @imgPriv[w][0] = im
      @imgPriv[w][:args] = keys
      Tk.update_idletasks
      Tk.after(20, proc{update_animated_gif(w, :image, 0)})
      puts "loaded animated gif"
    rescue => e
      w.configure(:text=>"error displaying animated gif:\n#{e.message}",
                  :image=>'', :relief=>:ridge)
    end
    w.pack
  end

  def show_image(fmt, type, data)
    fmt = fmt.to_s.capitalize
    unless @typeFrame[fmt]
      @typeFrame[fmt] = TkFrame.new.pack(:side=>:top, :expand=>true, :fill=>:x)
      TkLabel.new(@typeFrame[fmt], :text=>"#{fmt} :  ").pack(:side=>:left)
    end
    begin
      f = TkFrame.new(@typeFrame[fmt],
                      :borderwidth=>2, :relief=>:ridge).pack(:side=>:left)
      im = TkPhotoImage.new(:data=>data)
      im['data'] = ''
      TkLabel.new(f, :image=>im).pack
      TkLabel.new(f, :text=>type, :borderwidth=>0, :pady=>0, :padx=>2,
                  :font=>'Helvetica 8').pack
      puts "loaded #{fmt.downcase} #{type}"
    rescue => e
      TkMessage.new(f, :text=>"error displaying #{type} image: #{e.message}",
                    :aspect=>250).pack
    end
    Tk.update
  end

  # Load image from file (for formats that don't support base64 -data)
  # format_opts can be used to pass format-specific options (e.g., zoom for PS/PDF)
  def show_image_file(fmt, type, filepath, format_opts = nil)
    fmt = fmt.to_s.capitalize
    unless @typeFrame[fmt]
      @typeFrame[fmt] = TkFrame.new.pack(:side=>:top, :expand=>true, :fill=>:x)
      TkLabel.new(@typeFrame[fmt], :text=>"#{fmt} :  ").pack(:side=>:left)
    end
    begin
      f = TkFrame.new(@typeFrame[fmt],
                      :borderwidth=>2, :relief=>:ridge).pack(:side=>:left)
      img_opts = {:file=>filepath}
      img_opts[:format] = format_opts if format_opts
      im = TkPhotoImage.new(img_opts)
      TkLabel.new(f, :image=>im).pack
      TkLabel.new(f, :text=>type, :borderwidth=>0, :pady=>0, :padx=>2,
                  :font=>'Helvetica 8').pack
      puts "loaded #{File.basename(filepath)}"
    rescue => e
      TkMessage.new(f, :text=>"error displaying #{type} image: #{e.message}",
                    :aspect=>250).pack
    end
    Tk.update
  end

end

##############

demo = TkImg_demo.new

##############


# Fixture files for formats that don't support base64 -data natively.
#
# BMP/JPEG/TIFF files were generated from test/fixtures/sample.png using ImageMagick:
#   magick sample.png -resize 64x64 -monochrome BMP3:bmp_1bit.bmp
#   magick sample.png -resize 64x64 -colors 16 -type palette BMP3:bmp_4bit.bmp
#   magick sample.png -resize 64x64 -colors 256 -type palette -compress None BMP3:bmp_8bit.bmp
#   magick sample.png -resize 64x64 -colors 256 -type palette -compress RLE BMP3:bmp_8bit_rle.bmp
#   magick sample.png -resize 64x64 BMP3:bmp_24bit.bmp
#   magick sample.png -resize 64x64 jpeg_color.jpg
#   magick sample.png -resize 64x64 -colorspace Gray jpeg_grayscale.jpg
#   magick sample.png -resize 64x64 -interlace Line jpeg_progressive_color.jpg
#   magick sample.png -resize 64x64 -colorspace Gray -interlace Line jpeg_progressive_grayscale.jpg
#   magick sample.png -resize 64x64 -compress None tiff_uncompressed.tiff
#   magick sample.png -resize 64x64 -compress RLE tiff_packbits.tiff
#   magick sample.png -resize 64x64 -compress Zip tiff_deflate.tiff
#   magick sample.png -resize 64x64 -compress JPEG tiff_jpeg.tiff
#   magick sample.png -resize 64x64 -compress LZW tiff_lzw.tiff
#   magick sample.png -resize 64x64 postscript.ps
#
# Base64 fixtures (gif_*.b64, png_*.b64, xbm_*.b64) were extracted from the
# original Tcl/Tk Img extension demo.tcl which embeds image data inline.
# GIF and PNG support base64 -data natively in Tk.
#
FIXTURE_DIR = File.join(File.dirname(__FILE__), 'fixtures')
demo.show_animated_gif(:data=>File.read(File.join(FIXTURE_DIR, 'gif_animated.b64')))

demo.show_image_file('bmp', '1-bit', File.join(FIXTURE_DIR, 'bmp_1bit.bmp'))

demo.show_image_file('bmp', '4-bit', File.join(FIXTURE_DIR, 'bmp_4bit.bmp'))
demo.show_image_file('bmp', '8-bit', File.join(FIXTURE_DIR, 'bmp_8bit.bmp'))
demo.show_image_file('bmp', '8-bit-RLE', File.join(FIXTURE_DIR, 'bmp_8bit_rle.bmp'))
demo.show_image_file('bmp', '24-bit', File.join(FIXTURE_DIR, 'bmp_24bit.bmp'))

demo.show_image('gif', 'gif87a', File.read(File.join(FIXTURE_DIR, 'gif_87a.b64')))
demo.show_image('gif', 'gif89a', File.read(File.join(FIXTURE_DIR, 'gif_89a.b64')))

teapot = File.read(File.join(FIXTURE_DIR, 'teapot.xpm'))

demo.show_image('xpm', 'color', "/* XPM */
static char * teapot[] = {
\"64 48 204 2\",
\"   c #145ec4#{teapot}")
demo.show_image('xpm', 'transparent', "/* XPM */
static char * teapot[] = {
\"64 48 204 2\",
\"   s None c None#{teapot}")
demo.show_image('xbm', 'bitmap', File.read(File.join(FIXTURE_DIR, 'xbm_bitmap.b64')))

demo.show_image('png', 'color', File.read(File.join(FIXTURE_DIR, 'png_color.b64')))
demo.show_image('png', 'grayscale', File.read(File.join(FIXTURE_DIR, 'png_grayscale.b64')))
demo.show_image('png', 'transparent color', File.read(File.join(FIXTURE_DIR, 'png_transparent_color.b64')))
demo.show_image('png', 'transparent grayscale', File.read(File.join(FIXTURE_DIR, 'png_transparent_grayscale.b64')))

demo.show_image_file('jpeg', 'color', File.join(FIXTURE_DIR, 'jpeg_color.jpg'))
demo.show_image_file('jpeg', 'grayscale', File.join(FIXTURE_DIR, 'jpeg_grayscale.jpg'))
demo.show_image_file('jpeg', 'progressive color', File.join(FIXTURE_DIR, 'jpeg_progressive_color.jpg'))
demo.show_image_file('jpeg', 'progressive grayscale', File.join(FIXTURE_DIR, 'jpeg_progressive_grayscale.jpg'))


demo.show_image_file('tiff', 'uncompressed', File.join(FIXTURE_DIR, 'tiff_uncompressed.tiff'))
demo.show_image_file('tiff', 'packbits', File.join(FIXTURE_DIR, 'tiff_packbits.tiff'))
demo.show_image_file('tiff', 'deflate', File.join(FIXTURE_DIR, 'tiff_deflate.tiff'))
demo.show_image_file('tiff', 'jpeg compressed', File.join(FIXTURE_DIR, 'tiff_jpeg.tiff'))
demo.show_image_file('tiff', 'lzw', File.join(FIXTURE_DIR, 'tiff_lzw.tiff'))

if Tk::PLATFORM['platform'] != 'windows'
  demo.show_image_file('other', 'postscript', File.join(FIXTURE_DIR, 'postscript.ps'))
end

# PDF is intentionally not demonstrated here due to a limitation in tkimg's PDF handler.
# Unlike PostScript (which parses %%BoundingBox to determine image dimensions), the PDF
# handler in tkimg hardcodes A4 page size (21.0 x 29.7 cm = ~595x842 pixels at 72 DPI).
#
# From tkimg source ps.c lines 653-661 (CommonMatchPDF function):
#
#   /* Here w and h should be set to the bounding box of the pdf
#    * data. But I don't know how to extract that from the file.
#    * For now I just assume A4-size with 72 pixels/inch. If anyone
#    * has a better idea, please mail to <nijtmans@users.sourceforge.net>.
#    */
#   w = (int) round ((21.0 / 2.54 * 72.0));
#   h = (int) round ((29.7 / 2.54 * 72.0));
#
# This causes any PDF to render as a huge A4-sized image regardless of actual content.

#######################

# Automated test/record support
require 'tk/demo_support'

if TkDemo.active?
  puts 'tkimg demo loaded'
  $stdout.flush

  # Images are already loaded; wait for window to render then finish
  Tk.after(TkDemo.delay(test: 50, record: 1500)) {
    TkDemo.capture_thumbnail if TkDemo.recording?
    TkDemo.finish
  }
end

Tk.mainloop
