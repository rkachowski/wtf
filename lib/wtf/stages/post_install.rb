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

      #pass thru
      {:installed_devices => options[:installed_devices]}
    end
  end
end
