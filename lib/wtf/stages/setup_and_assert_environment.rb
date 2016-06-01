module Wtf
  class SetupAndAssertEnvironment < Stage

    def initialize options
      super

      options[:unity_version] ||= "5.3.4"
    end

    def setup
      unless Util.is_available_in_env? "uvm"
        fail "Can't find uvm in build environment"
      end

      unless File.exists? "/Applications/Unity"
        fail "Can't find Unity installation at /Applications/Unity"
      end

      unless UVM::Lib.list.include? options[:unity_version]
        fail "Can't find requested unity version - #{options[:unity_version]}, available versions are #{UVM::Lib.list.join(", ")}"
      end
    end


    def perform
      uvm = UVM::CLI.new [], [], []

      Wtf.log "Using unity version #{options[:unity_version]}"
      uvm.use options[:unity_version]

      Wtf.log "Build environment:"
      Wooget::Util.run_cmd "( set -o posix ; set )"

      Wtf.log "Attached Devices:"
      Wtf.log "  Android:"
      Android.devices.each do |device|
        Wtf.log "    #{device}"
      end

      Wtf.log "Wtf Options:"
      Wtf.log options
    end
  end
end

