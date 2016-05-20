require "thor"
require "wooget"
require "uvm"
require 'logger'

require_relative "wtf/version"
require_relative "wtf/stage"
require_relative "wtf/stages/generate_project"
require_relative "wtf/stages/install_dependencies"
require_relative "wtf/stages/build_editor_assembly"
require_relative "wtf/stages/create_test_scene"
require_relative "wtf/stages/build"


require_relative "wtf/unity"
require_relative "wtf/cli"
require_relative "wtf/misc"

module Wtf
  @@log = Logger.new(STDOUT)
  @@log.formatter = proc do |severity, datetime, progname, msg|
    "#{msg}\n"
  end
  @@log.level = Logger::Severity::DEBUG
  Wooget.log = @@log

  def self.log
    @@log
  end
end

