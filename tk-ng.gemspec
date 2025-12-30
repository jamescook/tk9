Gem::Specification.new do |spec|
  spec.name          = "tk-ng"
  spec.version       = "1.0.0"
  spec.authors       = ["SHIBATA Hiroshi", "Nobuyoshi Nakada", "Jeremy Evans"]
  spec.email         = ["hsbt@ruby-lang.org", "nobu@ruby-lang.org", "code@jeremyevans.net"]

  spec.summary       = %q{Tk interface module with Tcl/Tk 8.6+ and 9.x support.}
  spec.description   = %q{Tk interface module using tcltklib. Fork of ruby/tk with Tcl/Tk 9.x compatibility.}
  spec.homepage      = "https://github.com/jamescook/tk-ng"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/tk/extconf.rb", "ext/tk/tkutil/extconf.rb"]
  spec.required_ruby_version = ">= 3.2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.0"

  spec.metadata["msys2_mingw_dependencies"] = "tk"
end
