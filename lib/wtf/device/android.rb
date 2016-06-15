module Wtf
  class Android < Thor
    include Thor::Actions
    class_option :device, required: true, :desc => 'Device serial number'
    attr_reader :log

    def initialize(args = [], options = {}, config = {})
      super
      @log = []
      @log_mutex = Mutex.new
    end

    option :name, desc: "name of the file", default:`date +"%m-%d-%y-%T%d"`.chomp, type: :string
    desc "screenshot", "Take a screenshot"
    def screenshot
      name = options[:name]
      name = name + ".png" unless name.end_with? ".png"

      execute_cmd "shell screencap /sdcard/#{name}"
      execute_cmd "pull /sdcard/#{name}"
    end

    option :component, desc: "The intended recipient component", type: :string
    option :es_k, desc: "Extra string data key", type: :string
    option :es_v, desc: "Extra string data value", type: :string
    option :data_uri, desc: "string data uri", type: :string
    desc "broadcast ACTION", "broadcast an intent with a specific action"
    def broadcast action
      extra = ""
      if options[:es_k] and options[:es_v]
        extra = " --es '#{[:es_k]}' '#{options[:es_v]}' "
      end

      cmd = "shell am broadcast -a #{action} #{"-n '#{options[:component] }' " if options[:component] } #{"-d '#{options[:data_uri] }' " if options[:data_uri] } " + extra
      execute_cmd cmd
    end

    desc "install_referrer VALUE BUNDLE_ID", "Broadcast install referral just like the play store"
    def install_referrer referral_value, bundle_id

      broadcast_options = {}
      broadcast_options[:component] = "#{bundle_id}/com.wooga.sdk.InstallReferrerReceiver"
      broadcast_options[:es_k] = "referrer"
      broadcast_options[:es_v] = referral_value
      action = "com.android.vending.INSTALL_REFERRER"

      invoke "broadcast", [action], broadcast_options.merge(options)
    end

    desc "installed? package_id", "Is a package installed on the device"
    def installed? package_id
      package_id = self.class.get_package_name(package_id) if package_id.end_with? ".apk"

      output = execute_cmd "shell pm list packages #{package_id}"
      not output.empty?
    end

    desc "clear_logs", "clear logcat on device"
    def clear_logs
      execute_cmd "logcat -c"
    end

    desc "launch package_id/apk","Launch the activity for the chosen package"
    def launch package_id
      package_id = self.class.get_package_name(package_id) if package_id.end_with? ".apk"

      execute_cmd "shell monkey -p #{package_id} -c android.intent.category.LAUNCHER 1"
    end

    desc "kill package_id/apk", "Kill the activity with the provided package id"
    def kill package_id
      package_id = self.class.get_package_name(package_id) if package_id.end_with? ".apk"

      execute_cmd "shell am force-stop #{package_id}"
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

      execute_cmd "install '#{apk}'"
    end

    desc "menu", "press menu button on android device"
    def menu
      execute_cmd "shell input keyevent KEYCODE_MENU"
    end

    desc "power", "press power button"
    def power
      execute_cmd "shell input keyevent KEYCODE_POWER"
    end

    desc "back", "press back button"
    def back
      execute_cmd "shell input keyevent KEYCODE_BACK"
    end

    desc "home", "press home button"
    def home
      execute_cmd "shell input keyevent KEYCODE_HOME"
    end

    desc "input_pin PIN","inputs the pin and press enter"
    def input_pin pin="0000"
      execute_cmd "shell input text #{pin}"
      execute_cmd "shell input keyevent KEYCODE_ENTER"
    end

    desc "pull PATH","Pull a file from the path to pwd"
    def pull path, destination=Dir.pwd
      execute_cmd "pull #{path} #{destination}"
    end

    desc "attach_logcat", "start collecting log info from device"
    def attach_logcat
      if @log_thread
        Wtf.log.info "Trying to attach logcat to #{id} whilst already attached"
        return
      end

      @log_thread = Thread.new { Wooget::Util.run_cmd("adb #{ "-s #{options[:device]} logcat" if options[:device] }") {|log| on_log(log) } }
    end

    desc "detach_logcat", "stop grabbing logs"
    def detach_logcat
      return unless @log_thread

      @log_thread.exit
      @log_thread = nil
    end

    desc "screen_active?", "is the screen currently active (PowerManager.isInteractive() )"
    def screen_active?
      parcel = execute_cmd("shell dumpsys power | grep mHoldingDisplaySuspendBlocker").first
      puts parcel
      matches = parcel.match /mHoldingDisplaySuspendBlocker=(\w+)/

      return matches[1] == "true" if matches
      nil
    end

    desc "unlock_swipe", "do an unlock swipe"
    def unlock_swipe
      resolution #make sure we have this

      #swipe up the center of the screen from 20% above the bottom of the phone to 20% below the top
      centre_x = @resolution[0] / 2
      start_y = @resolution[1] / 10 * 8
      end_y = @resolution[1] / 10 * 2
      duration_ms = 300

      execute_cmd "shell input swipe #{centre_x} #{start_y} #{centre_x} #{end_y} #{duration_ms}"
    end
no_commands do
    def self.get_package_name apk
      package_line = `aapt dump badging '#{apk}' | grep package`.chomp

      package_line.scan(/name='([a-zA-Z\.]+)'/).flatten.first
    end

    def self.devices
      adb_output = %x{adb devices}.chomp.lines
      devices = adb_output.map{ |l| l.scan /(^[0-9a-f]+)\s(?:device)/ }

      devices.select{|r| not r.empty? }.flatten
    end

    def self.all fresh_install=true
      devices.map {|d| Android.new([],{device: d, fresh_install: fresh_install})}
    end

    def on_log log
      @log_mutex.synchronize { @log << log }
    end

    def log_contains str
      @log_mutex.synchronize { @log.any? {|line| line =~ /#{Regexp.escape(str)}/ } }
    end

    def id
      options[:device]
    end

    def get_prop property_name
      @props ||= execute_cmd "shell getprop"

      property_value = ""

      line = @props.find {|p| p =~ /#{Regexp.escape(property_name)}/ }
      match = line.match(/(?:\[.*\]).*\[(.*)\]/) if line
      property_value = match[1] if match and match[1]

      property_value
    end

    def model
      @model ||= get_prop "ro.product.model"
      @model
    end

    def api_level
      @api_level ||= get_prop "ro.build.version.sdk"
      @api_level
    end

    def android_version
      @android_version ||= get_prop "ro.build.version.release"
      @android_version
    end

    def arch
      @arch ||= get_prop "ro.product.cpu.abilist"
      @arch
    end

    def resolution
      unless @resolution
        size = execute_cmd("shell wm size").first
        matches = size.match /(\d+)x(\d+)/

        @resolution = [matches[1].to_i,matches[2].to_i] if matches
      end
      @resolution
    end
    def to_s
      "#{model} (serial=#{id} api_level=#{api_level} android=#{android_version} arch=#{arch})"
    end

    def execute_cmd cmd
      str = "adb #{ "-s #{options[:device]}" if options[:device] } #{cmd}"
      Wtf.log.info "Running: #{str}"
      %x{#{str}}.chomp.lines
    end
end


  end
end
