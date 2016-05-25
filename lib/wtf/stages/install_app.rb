require 'timeout'

module Wtf
  class InstallApp < Stage
    INSTALL_TIME = 60

    def setup
      fail("No valid devices to install to were provided") unless options[:devices]

      case options[:platform]
        when "android"
          fail("No android devices found") unless options[:devices][:android].count > 0
          fail("Invalid apk file at #{options[:path]}") unless File.exists?(options[:path])
        when "ios"
          fail("No ios devices found") if options[:platform] == "ios" and not options[:devices][:ios].count > 0
      end
    end

    def perform
      target_device_ids = options[:devices][options[:platform].to_sym]
      Wtf.log.info "Installing #{options[:path]} to #{options[:platform]} devices : #{target_device_ids}\n"

      result = {installed_devices:[]}

      if options[:platform] == "android"
        mutex = Mutex.new
        devices = target_device_ids.map {|d| ADB.new([],{device: d})}

        install_threads = devices.map do |device|
          Thread.new do
            begin
              Timeout.timeout(INSTALL_TIME) do
                device.install options[:path]
              end
            rescue Exception => e
              Wtf.log.info "Error installing to android device #{device.options[:device]} - #{e.message}"
            end

            mutex.synchronize { result[:installed_devices] << device }
          end
        end

        install_threads.each {|t| t.join }
      end

      result
    end
  end
end
