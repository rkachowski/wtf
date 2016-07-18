require 'CFPropertyList'
require 'zip'
require 'fileutils'

module Wtf
  class IOS < Thor
    IMOBILEDEVICE = File.join(File.dirname(__FILE__), "..", "..", "imobiledevice", "bin")

    include Thor::Actions
    class_option :device, required: true, :desc => 'Device serial number'
    attr_reader :applog, :syslog

    def initialize(args = [], options = {}, config = {})
      super
      @syslog = []
      @syslog_mutex = Mutex.new
      @applogs = {}
      @applog_mutexes = {}
    end

    desc "screenshot", "Take a screenshot"
    def screenshot name=`date +"%m-%d-%y-%T%d"`.strip
      # TODO-IOS: convert to png?
      name = name + ".tiff" unless name.end_with? ".tiff"

      %x{#{IMOBILEDEVICE}/idevicescreenshot -u #{self.id} "#{name}"}
    end

    desc "installed? PKG", "Is a package installed on the device"
    def installed? pkg
      bundle_id = self.class.resolve_bundle_id(pkg)
      self.apps.any? { |app| app["CFBundleIdentifier"] == bundle_id.strip }
    end

    desc "launch PKG", "Launch the application from the specified package"
    def launch pkg
      bundle_id = self.class.resolve_bundle_id(pkg)
      @app_thread = Thread.new { 
        Wooget::Util.run_cmd("#{IMOBILEDEVICE}/idevicedebug -u #{self.id} run #{bundle_id}") { |log| on_applog(bundle_id, log) }
      }
      bundle_id
    end

    option :fresh_install, desc: "Should old packages be uninstalled before replacement", type: :boolean, default: true
    desc "install IPA", "install the ipa file"
    def install ipa
      Wtf.log.info "Installing '#{ipa}' to #{options[:device]}..."

      if options[:fresh_install]
        bundle_id = self.class.get_bundle_id(ipa)
        if installed? bundle_id
          Wtf.log.info "#{bundle_id} exists on #{self.id} already, uninstalling..."
          %x{#{IMOBILEDEVICE}/ideviceinstaller -u #{self.id} -U #{bundle_id}}
        end
      end

      %x{#{IMOBILEDEVICE}/ideviceinstaller -u #{self.id} -i #{ipa}}
    end

    desc "attach_log", "start collecting syslog info from device"
    def attach_log
      if @syslog_thread
        Wtf.log.info "Trying to attach log to #{id} whilst already attached"
        return
      end

      @syslog_thread = Thread.new { Wooget::Util.run_cmd("#{IMOBILEDEVICE}/idevicesyslog -u #{options[:device]}") {|log| on_syslog(log) } }
    end

    desc "detach_log", "stop grabbing syslog"
    def detach_log
      return unless @syslog_thread

      @syslog_thread.exit
      @syslog_thread = nil
    end

    desc "pull PATH","Pull a file from the media folder to pwd"
    def pull path, destination=Dir.pwd, bundle_id: nil
      self.with_mount(bundle_id) do |mount_point|
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
      # TODO: implement me correctly
      @app_thread.exit
      @app_thread = nil
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
      %x{idevice_id -l}.chomp.lines.select{|r| not r.empty? }.flatten.map { |d| d.strip }
    end

    def self.all fresh_install=true
      devices.map {|d| IOS.new([], { device: d, fresh_install: fresh_install })}
    end

    def apps
      self.class.parse_plist %x{#{IMOBILEDEVICE}/ideviceinstaller -u #{self.id} -l -o xml}
    end

    def get_app_path bundle_id
      self.apps.select { |app| app["CFBundleIdentifier"] == bundle_id}.first["Path"]
    end

    def on_syslog log
      @syslog_mutex.synchronize { @syslog << log }
    end

    def syslog_contains str
      @syslog_mutex.synchronize { @syslog.any? {|line| line =~ /#{Regexp.escape(str)}/ } }
    end

    def on_applog bundle_id, log
      @applog_mutexes[bundle_id] = Mutex.new unless @applog_mutexes[bundle_id]
      @applog_mutexes[bundle_id].synchronize { 
        @applogs[bundle_id] = [] unless @applogs[bundle_id]
        @applogs[bundle_id] << log 
      }
    end

    def applog_contains bundle_id, str
      if @applogs[bundle_id]
        @applog_mutexes[bundle_id].synchronize { 
          @applogs[bundle_id].any? {|line| line =~ /#{Regexp.escape(str)}/ } 
        }
      end
    end

    def log bundle_id: nil
      if bundle_id and @applogs[bundle_id]
        @applogs[bundle_id]
      elsif @syslog_thread
        @syslog
      else
        []
      end
    end

    def log_contains str, bundle_id: nil
      # TODO: review this
      if bundle_id and @applogs[bundle_id]
        applog_contains(bundle_id, str)
      elsif @syslog_thread
        syslog_contains(str)
      end
    end

    def mounted?(mount_point)
      not mount_point.nil?
    end

    def with_automation_script run_timeout
      # TODO: migrate loading templates to a helper
      template_path = File.join(File.dirname(__FILE__), "..", "templates", "run_app.js.erb")
      tmp = Tempfile.new("run_app.js") 
      tmp.write(ERB.new(File.open(template_path).read).result(binding))
      tmp.close

      yield(tmp.path)

      tmp.unlink
    end

    # Mounts the document folder of the app with the specified bundle id,
    # otherwise mounts the media folder of a device. Returns the mount point folder.
    def mount(bundle_id=nil)
      app_arg = bundle_id ? "--documents '#{bundle_id}'" : ""
      mount_point = Dir.tmpdir
      %x{ifuse #{app_arg} -u #{self.id} #{mount_point}}
      fail("can't mount ios device #{self.id} at #{mount_point}") unless $?.success?
      mount_point
    end

    def umount(mount_point)
      if self.mounted?(mount_point)
        %x{umount #{mount_point}}
        fail("can't umount ios device #{self.id} at #{mount_point}") unless $?.success?
      end
    end

    def with_mount bundle_id=nil
      mount_point = self.mount(bundle_id)
      begin
        result = yield(mount_point)
      ensure
        self.umount(mount_point)
      end
      result
    end

    def id
      options[:device]
    end

    def device_info property_name=nil
      @props ||= self.class.parse_plist(%x{#{IMOBILEDEVICE}/ideviceinfo -u #{self.id} -x})
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
