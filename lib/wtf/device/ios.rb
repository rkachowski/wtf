require 'CFPropertyList'
require 'zip'
require 'fileutils'

module Wtf
  class IOS < Thor
    include Thor::Actions
    class_option :device, required: true, :desc => 'Device serial number'
    attr_reader :log

    def initialize(args = [], options = {}, config = {})
      super
      @log = []
      @log_mutex = Mutex.new
      @mount_point = nil
    end

    desc "screenshot", "Take a screenshot"
    def screenshot name=`date +"%m-%d-%y-%T%d"`.strip
      # TODO-IOS: convert to png?
      name = name + ".tiff" unless name.end_with? ".tiff"

      %x{idevicescreenshot -u #{self.id} "#{name}"}
    end

    desc "installed? PKG", "Is a package installed on the device"
    def installed? pkg
      bundle_id = self.class.resolve_bundle_id(pkg)
      self.apps.each do |app|
        if app["CFBundleIdentifier"] == bundle_id.strip
          return true
        end
      end

      false
    end

    desc "launch BUNDLE_ID", "Launch the application with the specified bundle id"
    def launch bundle_id
      %x{idevicedebug -u #{self.id} run #{bundle_id}}
    end

    option :fresh_install, desc: "Should old packages be uninstalled before replacement", type: :boolean, default: true
    desc "install IPA", "install the ipa file"
    def install ipa
      Wtf.log.info "Installing '#{ipa}' to #{options[:device]}..."

      if options[:fresh_install]
        bundle_id = self.class.get_bundle_id(ipa)
        if installed? bundle_id
          Wtf.log.info "#{bundle_id} exists on #{self.id} already, uninstalling..."
          %x{ideviceinstaller -u #{self.id} -U #{bundle_id}}
        end
      end

      %x{ideviceinstaller -u #{self.id} -i #{ipa}}
    end

    desc "attach_log", "start collecting log info from device"
    def attach_log
      if @log_thread
        Wtf.log.info "Trying to attach log to #{id} whilst already attached"
        return
      end

      @log_thread = Thread.new { Wooget::Util.run_cmd("idevicesyslog -u #{options[:device]}") {|log| on_log(log) } }
    end

    desc "detach_log", "stop grabbing logs"
    def detach_log
      return unless @log_thread

      @log_thread.exit
      @log_thread = nil
    end

    desc "pull PATH","Pull a file from the media folder to pwd"
    def pull path, destination=Dir.pwd
      self.with_mount do |mount_point|
        source = File.join(mount_point, path)
        FileUtils.cp(source, destination)
      end
    end

    desc "screen_active?", "is the screen currently active (PowerManager.isInteractive() )"
    def screen_active?
      # TODO: implement me
      true
    end
 
    desc "power", "press power button"
    def power
      # TODO: implement me maybe
    end

    desc "kill bundle_id/ipa", "Kill the activity with the provided package id"
    def kill pkg
      # TODO: implement me
      fail("not implemented")
    end

no_commands do
    def self.parse_plist str
      CFPropertyList.native_types(CFPropertyList::List.new(:data => str).value)
    end

    def self.get_bundle_id ipa
      Zip::File.open(ipa) do |zip_file|
        zip_entry = zip_file.glob('Payload/**/Info.plist').first
        info_plist = zip_entry.get_input_stream.read
        ipa_info = parse_plist(info_plist)
        ipa_info["CFBundleIdentifier"]
      end
    end

    def self.resolve_bundle_id pkg
      pkg.end_with?(".ipa") ? self.get_bundle_id(pkg) : pkg
    end

    def self.devices
      %x{idevice_id -l}.chomp.lines.select{|r| not r.empty? }.flatten
    end

    def self.all fresh_install=true
      devices.map {|d| IOS.new([],{device: d, fresh_install: fresh_install})}
    end

    def apps
      self.class.parse_plist %x{ideviceinstaller -u #{self.id} -l -o xml}
    end

    def get_app_path bundle_id
      self.apps.select { |app| app["CFBundleIdentifier"] == bundle_id}.first["Path"]
    end

    def on_log log
      @log_mutex.synchronize { @log << log }
    end

    def log_contains str
      @log_mutex.synchronize { @log.any? {|line| line =~ /#{Regexp.escape(str)}/ } }
    end

    def mounted?
      not @mount_point.nil?
    end

    def mount
      unless self.mounted?
        @mount_point = Dir.tmpdir
        %x{ifuse -u #{self.id} #{@mount_point}}
        fail("can't mount ios device #{self.id} at #{@mount_point}") unless $?.success?
      end
      @mount_point
    end

    def umount
      if self.mounted?
        %x{umount #{@mount_point}}
        fail("can't umount ios device #{self.id} at #{@mount_point}") unless $?.success?
        @mount_point = nil
      end
    end

    def with_mount
      self.mount
      result = yield @mount_point
      self.umount
      result
    end

    def id
      options[:device]
    end

    def device_info property_name=nil
      @props ||= self.class.parse_plist(%x{ideviceinfo -u #{self.id} -x})
      if property_name
        @props[property_name]
      else
        @props
      end
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

    def to_s
      "#{model} (serial=#{id} ios_version=#{ios_version} arch=#{arch})"
    end
end

  end
end
