module Wtf
  class PostInstall < Stage
    POST_INSTALL_TIME_SECONDS = 60

    def device_error msg
      { :status => :error, :data => { :platform => options[:platform], :error => msg }}
    end

    def perform
      valid_devices = []
      invalid_devices = {}

      devices = options[:installed_devices]
      mutex = Mutex.new

      case options[:platform] 
      when "android"
        threads = devices.map do |device|
          Thread.new do
            begin
              Timeout.timeout(POST_INSTALL_TIME_SECONDS) do
                device.clear_logs

                #todo: broadcast install referral

                unless device.screen_active?
                  device.power
                  device.unlock_swipe
                end

                device.home
              end
            rescue Exception => e
              mutex.synchronize do
                invalid_devices[device] = device_error(e.message)
              end
            end
          end
        end
        threads.each { |t| t.join }
      end

      options[:installed_devices].each do |device|
        next if invalid_devices[device]

        if device.installed? options[:pkg]
          valid_devices << device
        else
          error_msg = "Error with #{device} - #{options[:pkg]} is not installed"

          Wtf.log.error error_msg
          invalid_devices[device] = device_error(error_msg) 
        end
      end

      {:installed_devices => valid_devices, :errored_devices => invalid_devices}
    end
  end
end
