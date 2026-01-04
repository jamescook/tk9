# frozen_string_literal: false
require 'tk'

class Button_with_Frame < TkButton
  def create_self(keys)
    @frame = TkFrame.new('widgetname'=>@path, 'background'=>'yellow')
    install_win(@path) # create new @path which is a daughter of old @path
    super(keys)
    TkPack(@path, :padx=>7, :pady=>7)
    @epath = @frame.path
  end
  def epath
    @epath
  end
end

btn = Button_with_Frame.new(:text=>'QUIT', :command=>proc{
  puts 'QUIT clicked'
  exit
}) {
  pack(:padx=>15, :pady=>5)
}

# Smoke test support
if ENV['TK_READY_FD']
  Tk.root.bind('Visibility') {
    Tk.after(50) {
      # Don't invoke QUIT - it calls exit which is unsafe from callback
      # Just verify the UI loaded
      puts 'UI loaded'
      $stdout.flush

      if (fd = ENV.delete('TK_READY_FD'))
        IO.for_fd(fd.to_i).tap { |io| io.write("1"); io.close } rescue nil
      end

      # Exit gracefully via after_idle (safe - not inside event processing)
      Tk.after_idle { Tk.root.destroy }
    }
  }
end

Tk.mainloop
