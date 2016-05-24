module Wtf
  class ADB < Thor
    include Thor::Actions
    class_option :device, :desc => 'Device serial number'

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


    desc "install_referrer VALUE BUNDLE_ID", "Broadcast install referral just like the app store"
    def install_referrer referral_value, bundle_id

      self.options = Thor::CoreExt::HashWithIndifferentAccess.new.merge(self.options)
      self.options[:component] = "#{bundle_id}/com.wooga.sdk.InstallReferrerReceiver"
      self.options[:es_k] = "referrer"
      self.options[:es_v] = referral_value
      action = "com.android.vending.INSTALL_REFERRER"

      broadcast action
    end

    desc "clear_logs", "clear logcat on device"
    def clear_logs
      cmd "logcat -c"
    end

    def install apk

    end

no_commands do
    def execute_cmd cmd
      str = "adb #{ "-s #{options[:device]}" if options[:device] } #{cmd}"
      Wtf.log.info "Running: #{str}"
      %x{#{str}}
    end
end


  end
end
