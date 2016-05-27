module Wtf
  class FindDevices < Stage

    def setup
      `type adb`
      fail "Can't find adb in path" unless $?.exitstatus == 0
    end

    def perform
      android = Android.all

      Wtf.log.info "Detected android devices: \n#{android.map{|a| " "*4+a.to_s}.join("\n")}"

      fail("No devices found!") if android.empty?

      {devices: android}
    end
  end
end
