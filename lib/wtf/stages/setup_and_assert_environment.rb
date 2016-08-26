require 'fileutils'

module Wtf
  class SetupAndAssertEnvironment < Stage

    def initialize options
      super

      options[:unity_version] ||= "5.4.0"
    end

    def setup
      unless Util.is_available_in_env? "uvm"
        fail "Can't find uvm in build environment"
      end

      unless Util.is_available_in_env? "mono"
        fail "Can't find mono in build environment"
      end

      unless File.exists? "/Applications/Unity"
        fail "Can't find Unity installation at /Applications/Unity"
      end

      unless UVM::Lib.list.include? options[:unity_version]
        fail "Can't find requested unity version - #{options[:unity_version]}, available versions are #{UVM::Lib.list.join(", ")}"
      end
    end


    def perform

      stuff_to_clean_up = Dir["*log", "*proj", "*apk", "*xml", "*logcat", "wtf.failure"]

      unless stuff_to_clean_up.empty?
        Wooget.log.info "Removing files generated from previous build - #{stuff_to_clean_up.join(", ")}"
        FileUtils.rm_r(stuff_to_clean_up)
      end

      uvm = UVM::CLI.new [], {}, {}

      Wtf.log.info "## Using unity version #{options[:unity_version]}"
      uvm.use options[:unity_version]


      env = ""
      Wooget::Util.run_cmd("( set -o posix ; set )") {|l| env << l}
      
      Wtf.log.info "\n## Build environment:\n"
      Wtf.log.info env

      gems = %w{wooga_wooget wooga_uvm wooga_wtf}
      gems.each do |gem|
        Wtf.log.info "#{gem} version: #{Gem.loaded_specs[gem]}"
      end

      Wtf.log.info "\n## Attached Devices:"
      Wtf.log.info "  Android:"
      Android.all.each do |device|
        Wtf.log.info "    #{device}"
      end
      Wtf.log.info "  iOS:"
      IOS.all.each do |device|
        Wtf.log.info "    #{device}"
      end

      Wtf.log.info "\n## Wtf Options:\n"
      Wtf.log.info options
    end
  end
end

