Gem::Specification.new do |s|
  s.name        = "riemann-ruby-experiments"
  s.version     = "0.0.4"
  s.licenses    = ["LGPL-3.0"]
  s.platform    = Gem::Platform::RUBY
  s.summary     = "A Riemann client for ruby"
  s.description = "Just another client, to experiment with."
  s.authors     = ["Chris Riddoch"]
  s.email       = "riddochc@gmail.com"
  s.date        = "2016-07-05"
  s.homepage    = "https://syntacticsugar.org/projects/riemann-ruby-experiments"
  s.files       = ["Gemfile",
                   "README.adoc",
                   "Rakefile",
                   "data/riemann.proto",
                   "lib/riemann-ruby-experiments/event.rb",
                   "lib/riemann-ruby-experiments/main.rb",
                   "lib/riemann-ruby-experiments/riemann.pb.rb",
                   "lib/riemann-ruby-experiments/version.rb",
                   "lib/riemann-ruby-experiments.rb",
                   "project.yaml",
                   "riemann-ruby-experiments.gemspec"]

  s.add_dependency "ruby-protocol-buffers", ">= 1.6.1"
  s.add_dependency "net_tcp_client", ">= 2.0.1"

  s.add_development_dependency "rake", "= 11.2.2"
  s.add_development_dependency "asciidoctor", "= 1.5.5.dev"
  s.add_development_dependency "yard", "= 0.8.7.6"
  s.add_development_dependency "pry", "= 0.10.3"
  s.add_development_dependency "rugged", "= 0.24.0"
  s.add_development_dependency "ruby-builtin-requireables", "= 0.0.1"
end
