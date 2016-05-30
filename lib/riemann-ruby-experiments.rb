#!/usr/bin/env ruby
#
require "protocol_buffers"
require "net/tcp_client"
require "English"
require 'set'
require 'date'

module Riemann
end

require_relative 'riemann-ruby-experiments/riemann.pb'
require_relative 'riemann-ruby-experiments/event.rb'
require_relative 'riemann-ruby-experiments/main'

# I do a lot of testing with pry.
if $0 == __FILE__
  require 'pry'
  c = Riemann::Experiment::Client.new()
  binding.pry
end
