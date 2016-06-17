require 'timeout'

module Wtf
  class InstallApp < Stage
    INSTALL_TIME = 60

    def setup
      fail("No valid devices to install to were provided") unless options[:devices]

      case options[:platform]
        when "android"
          fail("No android devices found") unless options[:devices] and options[:devices].count > 0
          fail("Invalid apk file at #{options[:path]}") unless File.exists?(options[:path])

          required_commands = %w(adb aapt)
          required_commands.each do |cmd|
            `type #{cmd}`
            fail "Can't find #{cmd} in path" unless $?.exitstatus == 0
          end

        when "ios"
          fail("No ios devices found") unless options[:devices][:ios].count > 0
      end
    end

    def perform
      devices = options[:devices]
      Wtf.log.info "Installing #{options[:path]} to #{options[:platform]} devices : #{devices.map{|a| a.options[:device]}}\n"

      result = {installed_devices:[], apk: options[:path]}

      if options[:platform] == "android"
        mutex = Mutex.new

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
