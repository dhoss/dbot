#!/usr/bin/env ruby

require 'dbot'

unless ARGV[0]
    STDERR.puts "usage: $0 <yaml config>"
    exit 1
end

DBot.new(ARGV[0]).run
