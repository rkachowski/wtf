require "thor"
require "wooget"
require "uvm"
require 'logger'

require_relative "wtf/version"
require_relative "wtf/stage"
require_relative "wtf/stages/generate_project"
require_relative "wtf/unity"
require_relative "wtf/cli"

module Wtf
  @@log = Logger.new(STDOUT)
  @@log.formatter = proc do |severity, datetime, progname, msg|
    "#{severity}: #{msg}\n"
  end
  @@log.level = Logger::Severity::DEBUG

  def self.log
    @@log
  end
end

