module Wtf
  class PostInstall < Stage
    def perform
      if options[:platform] == "android"
        devices = options[:installed_devices]

        devices.each do |device|
          device.clear_logs

          #todo: broadcast install referral

          unless device.screen_active?
            device.power
            device.unlock_swipe
          end

          device.home
        end
      end

      valid_devices = []
      options[:installed_devices].each do |device|
        if device.installed? options[:apk]
          valid_devices << device
        else
          Wtf.log.error "Error with #{device} - #{options[:apk]} is not installed"
        end
      end

      {:installed_devices => valid_devices}
    end
  end
end
