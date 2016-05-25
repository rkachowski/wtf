module Wtf
  class Android < Thor
    include Thor::Actions
    class_option :device, required: true, :desc => 'Device serial number'

    option :name, desc: "name of the file", default:`date +"%m-%d-%y-%T%d"`.chomp, type: :string
    desc "screenshot", "Take a screenshot"
    def screenshot
      name = options[:name]
      name = name + ".png" unless name.end_with? ".png"

      execute_cmd "screencap /sdcard/#{name}"
      execute_cmd "pull /sdcard/#{name}"
    end

    option :component, desc: "The intended recipient component", type: :string
    option :es_k, desc: "Extra string data key", type: :string
    option :es_v, desc: "Extra string data value", type: :string
    desc "broadcast ACTION", "broadcast an intent with a specific action"
    def broadcast action
      extra = ""
      if options[:es_k] and options[:es_v]
        extra = " --es '#{[:es_k]}' '#{options[:es_v]}' "
      end

      cmd = "shell am broadcast -a #{action} #{"-n '#{options[:component] }' " if options[:component] } " + extra
      execute_cmd cmd
    end


    desc "install_referrer VALUE BUNDLE_ID", "Broadcast install referral just like the play store"
    def install_referrer referral_value, bundle_id

      self.options = Thor::CoreExt::HashWithIndifferentAccess.new.merge(self.options)
      self.options[:component] = "#{bundle_id}/com.wooga.sdk.InstallReferrerReceiver"
      self.options[:es_k] = "referrer"
      self.options[:es_v] = referral_value
      action = "com.android.vending.INSTALL_REFERRER"

      broadcast action
    end

    desc "installed? package_id", "Is a package installed on the device"
    def installed? package_id
      output = execute_cmd "shell pm list packages #{package_id}"
      not output.empty?
    end

    desc "clear_logs", "clear logcat on device"
    def clear_logs
      execute_cmd "logcat -c"
    end

    option :package_name, desc: "package name / bundle id to be installed"
    option :fresh_install, desc: "Should old packages be uninstalled before replacement", type: :boolean, default: true
    desc "install APK", "install the apk file"
    def install apk
      Wtf.log.info "Installing #{apk} to #{options[:device]}..."

      if options[:fresh_install]
        package_name = options[:package_name] || self.class.get_package_name(apk)
        if installed? package_name
          Wtf.log.info "#{package_name} exists on #{options[:device]} already, uninstalling..."
          execute_cmd "uninstall #{package_name}"
        end
      end

      execute_cmd "install #{apk}"
    end

no_commands do
    def self.get_package_name apk
      package_line = `aapt dump badging #{apk} | grep package`.chomp

      package_line.scan(/name='([a-zA-Z\.]+)'/).flatten.first
    end

    def self.devices
      adb_output = %x{adb devices}.chomp.lines
      devices = adb_output.map{ |l| l.scan /(^[0-9a-f]+)\s(?:device)/ }

      devices.select{|r| not r.empty? }.flatten
    end

    def execute_cmd cmd
      str = "adb #{ "-s #{options[:device]}" if options[:device] } #{cmd}"
      Wtf.log.info "Running: #{str}"
      %x{#{str}}.chomp.lines
    end
end


  end
end
