module Wtf
  class FindDevices < Stage

    def setup
      `type adb`
      fail "Can't find adb in path" unless $?.exitstatus == 0
    end

    def perform
      platform = options[:platform] == "android" ? Android : IOS
      devices = platform.all

      Wtf.log.info "Detected #{options[:platform]} devices: \n#{devices.map{|a| "    #{a}"}.join("\n")}"

      fail("No devices found!") if devices.empty?

      {devices: devices}
    end
  end
end
