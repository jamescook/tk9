Gem::Specification.new do |spec|
  spec.name          = "tk-ng"
  spec.version       = "1.0.0"
  spec.authors       = ["SHIBATA Hiroshi", "Nobuyoshi Nakada", "Jeremy Evans"]
  spec.email         = ["hsbt@ruby-lang.org", "nobu@ruby-lang.org", "code@jeremyevans.net"]

  spec.summary       = %q{Tk interface module with Tcl/Tk 8.6+ and 9.x support.}
  spec.description   = %q{Tk interface module using tcltklib. Fork of ruby/tk with Tcl/Tk 9.x compatibility.}
  spec.homepage      = "https://github.com/jamescook/tk-ng"
  spec.license       = "BSD-2-Clause"

  spec.files         = Dir.glob("{lib,ext,exe,sample}/**/*").select { |f| File.file?(f) } +
                       %w[Rakefile LICENSE.txt README.md tk-ng.gemspec Gemfile]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/tk/extconf.rb", "ext/tk/tkutil/extconf.rb"]
  spec.required_ruby_version = ">= 3.2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "method_source", "~> 1.0"
  spec.add_development_dependency "prism", "~> 1.0"  # stdlib in Ruby 3.3+, gem for 3.2
  spec.add_development_dependency "base64"  # stdlib until Ruby 3.4, now bundled gem

  spec.metadata["msys2_mingw_dependencies"] = "tk"
end
