# vim: syntax=ruby

require 'yaml'
require 'find'
require 'asciidoctor'
require 'erb'

def installed_gem_version(name)
  IO.popen(["gem", "list", "-l", name], 'r') do |io|
    # this regex is using lookahead/behind to match things within \( and \), non-greedily.
    io.readlines.grep(/^#{name}\s/).first[/(?<=\().*?(?=\))/].split(', ').first
  end
end

def filtered_project_files()
  Dir.chdir __dir__ do
    Find.find(".").reject {|f| !File.file?(f) || f =~ %r{^\./(.git|tmp)} || f =~ %r{\.(so|gem)$} }.map {|f| f.sub %r{^\./}, '' }
  end
end

adoc = Asciidoctor.load_file("README.adoc")
summary = adoc.sections.find {|s| s.name == "Description" }.blocks[0].content.gsub(/\n/, ' ')
description = adoc.sections.find {|s| s.name == "Description" }.blocks[1].content.gsub(/\n/, ' ')
config = YAML.load_file(File.join(__dir__, "project.yaml"))
project = config.fetch('name', File.split(File.expand_path(__dir__)).last)
toplevel_module = config.fetch('toplevel_module') { project.capitalize }
version = adoc.attributes['revnumber']
dependencies = config.fetch('dependencies', {})
if dependencies.nil?
  dependencies = {}
end
dev_dependencies = config.fetch('dev-dependencies', {})
if dev_dependencies.nil?
  dev_dependencies = {}
end
license = config.fetch('license') { "LGPL-3.0" }

#["rake", "asciidoctor", "yard", "pry", "rspec", "rspec-sequel-formatter", "#{project}-tests"]
["rake", "asciidoctor", "yard", "pry"].each do |dep|
  dev_dependencies[dep] = dev_dependencies.fetch(dep) {|d| "=#{installed_gem_version(d)}" }
end

gemspec_template = <<GEMSPEC
Gem::Specification.new do |s|
  s.name        = "<%= project %>"
  s.version     = "<%= version %>"
  s.licenses    = ["<%= license %>"]
  s.platform    = Gem::Platform::RUBY
  s.summary     = "<%= summary %>"
  s.description = "<%= description %>"
  s.authors     = ["<%= adoc.author %>"]
  s.email       = "<%= adoc.attributes['email'] %>"
  s.date        = "<%= Date.today %>"
  s.files       = [<%= all_files.map{|f| '"' + f + '"' }.join(",\n                   ") %>]
  s.homepage    = "<%= adoc.attributes['homepage'] %>"

% dependencies.each_pair do |req, vers|
  s.add_dependency "<%= req %>", "<%= vers %>"
% end

% dev_dependencies.each_pair do |req, vers|
  s.add_development_dependency "<%= req %>", "<%= vers %>"
% end
end
GEMSPEC

task default: [:gen_version, :gemspec, :gemfile, :build]

task :gen_version do
  File.open(File.join("lib", project, "version.rb"), 'w') {|f|
    f.puts "module #{toplevel_module}"
    major, minor, tiny = *version.split(/\./).map {|p| p.to_i }
    f.puts '  VERSION = "' + version + '"'
    f.puts "  VERSION_MAJOR = #{major}"
    f.puts "  VERSION_MINOR = #{minor}"
    f.puts "  VERSION_TINY = #{tiny}"
    f.puts "end"
  }
end

task :gemspec => [:gen_version] do
  files_in_git = IO.popen(["git", "ls-files"], 'r') { |io| io.readlines.map {|l| l.chomp } }
  all_files = filtered_project_files()
  if all_files - files_in_git
    puts "Looks like there's some files uncommitted."
  end

  requires = all_files.grep(/\.rb$/).
                           map {|f| File.readlines(f).grep (/^\s*require(?!_relative)/) }.
                           flatten.
                           map {|line| line.split(/['"]/).at(1).split('/').at(0) }.
                           uniq

  missing_deps = requires - dependencies.keys
  if missing_deps.length > 0
    puts "There may be some dependencies not listed for the gemspec:"
    puts missing_deps.join(", ")
  end

  File.open(project + ".gemspec", 'w') do |f|
    erb = ERB.new(gemspec_template, nil, "%<>")
    f.write(erb.result(binding))
  end
end

task :gemfile do
  File.open("Gemfile", 'w') do |f|
    f.puts "source 'https://rubygems.org"
    f.puts "gemspec"
  end
end

task :build => [:gemspec] do
  system "gem build #{project}.gemspec"
end

task :install => [:build] do
  system "gem install ./#{project}-#{version}.gem"
end

task :clean do
  rm_f "./#{project}-#{version}.gem"
  rm_rf "tmp"
end
