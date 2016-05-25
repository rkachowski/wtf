module Wtf
  class FindDevices < Stage

    def setup
      `type adb`
      fail "Can't find adb in path" unless $?.exitstatus == 0
    end

    def perform
      android = Android.devices

      Wtf.log.info "Detected android devices: #{android}"

      fail("No devices found!") if android.empty?

      {devices: {android: android}}
    end
  end
end
