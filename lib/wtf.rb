require "thor"
require "wooget"
require 'logger'
require 'waitutil'
require 'nokogiri'

require_relative "wtf/version"

require_relative "wtf/stages/stage"
require_relative "wtf/stages/wooget_build"
require_relative "wtf/stages/generate_project"
require_relative "wtf/stages/install_dependencies"
require_relative "wtf/stages/build_editor_assembly"
require_relative "wtf/stages/create_test_scene"
require_relative "wtf/stages/android_build"
require_relative "wtf/stages/ios_build"
require_relative "wtf/stages/find_devices"
require_relative "wtf/stages/install_app"
require_relative "wtf/stages/post_install"
require_relative "wtf/stages/run_test_app"
require_relative "wtf/stages/pry_stage"
require_relative "wtf/stages/finalize_results"
require_relative "wtf/stages/setup_and_assert_environment"

require_relative "wtf/templates"
require_relative "wtf/device/android"
require_relative "wtf/device/ios"

require_relative "wtf/unity"
require_relative "wtf/stage_runner"
require_relative "wtf/cli"
require_relative "wtf/misc"
require_relative "wtf/xcodebuild"
require_relative "wtf/ci"

module Wtf
  @@log = Logger.new(STDOUT)
  @@log.formatter = proc do |severity, datetime, progname, msg|
    msg = msg.to_s
    msg = msg + "\n" unless msg.end_with? "\n"
    msg.start_with?("[quiet]") ? "#{msg.sub("[quiet]","")}" : msg
  end

  @@log.level = Logger::Severity::DEBUG
  Wooget.log = @@log

  def self.log
    @@log
  end
end

