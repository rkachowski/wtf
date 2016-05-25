module Wtf
  class FindDevices < Stage
    def perform
      android = ADB.devices

      Wtf.log.info "Detected android devices: #{android}"

      fail("No devices found!") if android.empty?

      {devices: {android: android} }
    end
  end
end
