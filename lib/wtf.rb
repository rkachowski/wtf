require "thor"
require_relative "wtf/version"
require_relative "wtf/stage"

module Wtf
  @@log = Logger.new(STDOUT)

  #always highest log level
  @@log.level = Logger::Severity::DEBUG
end

