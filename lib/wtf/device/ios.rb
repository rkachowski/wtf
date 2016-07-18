require 'CFPropertyList'
require 'zip'

module Wtf
  class IOS < Thor
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
      # TODO-IOS: convert to png?
      name = options[:name]
      name = name + ".tiff" unless name.end_with? ".tiff"

      %x{idevicescreenshot -u #{self.id} #{name}}
    end

    desc "installed? bundle_id", "Is a package installed on the device"
    def installed? bundle_id
      output = %x{ideviceinstaller -u #{self.id} -l}
      not output.empty?
    end

    desc "launch bundle_id", "Launch the application with the specified bundle id"
    def launch bundle_id
      package_id = self.class.get_package_name(package_id) if package_id.end_with? ".apk"

      app_path = get_app_path package_id
      %x{instruments -w #{self.id} -t /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.xrplugin/Contents/Resources/Automation.tracetemplate #{app_path}}
    end

    option :package_name, desc: "bundle id to be installed"
    option :fresh_install, desc: "Should old packages be uninstalled before replacement", type: :boolean, default: true
    desc "install IPA", "install the ipa file"
    def install ipa
      Wtf.log.info "Installing #{ipa} to #{options[:device]}..."

      if options[:fresh_install]
        bundle_id = self.class.get_bundle_id(ipa)
        if installed? package_name
          Wtf.log.info "#{package_name} exists on #{self.id} already, uninstalling..."
          %x{ideviceinstaller -u #{self.id} -U #{bundle_id}}
        end
      end

      %x{ideviceinstaller -u #{self.id} -i #{ipa}}
    end

    desc "pull PATH","Pull a file from the path to pwd"
    def pull path, destination=Dir.pwd
      # TODO-IOS: write application using afc_client?
    end

    desc "attach_log", "start collecting log info from device"
    def attach_log
      if @log_thread
        Wtf.log.info "Trying to attach logcat to #{id} whilst already attached"
        return
      end

      @log_thread = Thread.new { Wooget::Util.run_cmd("idevicesyslog -u #{options[:device]}") {|log| on_log(log) } }
    end

    desc "detach_logcat", "stop grabbing logs"
    def detach_log
      return unless @log_thread

      @log_thread.exit
      @log_thread = nil
    end

no_commands do
    def self.parse_plist str
      CFPropertyList.native_types(CFPropertyList::List.new(:data => str).value)
    end

    def self.get_app_path bundle_id
      app_list = parse_plist(%x{ideviceinstaller -l -o xml})
      app_list.select { |app| app["CFBundleIdentifier"] == bundle_id}.first["Path"]
    end

    def self.get_bundle_id ipa
      Zip::File.open(ipa) do |zip_file|
        zip_entry = zip_file.glob('Payload/Info.plist').first
        info_plist = zip_entry.get_input_stream.read
        ipa_info = parse_plist(info_plist)
        ipa_info["CFBundleIdentifier"]
      end
    end

    def self.devices
      %x{idevice_id -l}.chomp.lines.select{|r| not r.empty? }.flatten
    end

    def self.all fresh_install=true
      devices.map {|d| IOS.new([],{device: d, fresh_install: fresh_install})}
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

    def device_info property_name
      @props ||= self.parse_plist(%x{ideviceinfo -u #{self.id}}).device_info_plist.first
      @props[property_name]
    end

    def model
      @model ||= device_info "ProductType"
      @model
    end

    def ios_version
      @os_version ||= device_info "ProductVersion"
      @os_version
    end

    def arch
      @arch ||= device_info "CPUArchitecture"
      @arch
    end

    def resolution
      # TODO-IOS: implement this using a good old table
      unless @resolution
      end
      @resolution
    end

    def to_s
      "#{model} (serial=#{id} ios_version=#{ios_version} arch=#{arch})"
    end
end


  end
end
