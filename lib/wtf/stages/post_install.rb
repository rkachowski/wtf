module Wtf
  class PostInstall < Stage
    def perform
      if options[:platform] == "android"
        devices = options[:installed_devices]

        devices.each do |device|
          device.clear_logs

          #todo: broadcast install referral

          if device.screen_active?
            device.home
          else
            device.power
            device.unlock_swipe
          end
        end
      end

      #pass thru
      {:installed_devices => options[:installed_devices]}
    end
  end
end
