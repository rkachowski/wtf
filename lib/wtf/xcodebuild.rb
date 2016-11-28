require 'CFPropertyList'

module Wtf
  class XCodeBuild
    BIN = File.expand_path(File.join(File.dirname(__FILE__), "../util/xcbuild-safe.sh"))
    UNITY_SCHEME = "Unity-iPhone"
    UNITY_TARGET = "Unity-iPhone"

    def self.generate_options_plist path, options=nil
      # TODO: check those defaults
      options ||= {
          :compileBitcode => false,
          #:embedOnDemandResourcesAssetPacksInBundle => false,
          #:iCloudContainerEnvironment => "Development",
          #:manifest =>  {
          #  :appURL => "",
          #  :displayImageURL => "",
          #  :fullSizeImageURL => ""
          #},
          #:method => "Development",
          #:onDemandResourcesAssetPacksBaseURL => "",
          :teamID => "3LSB459Z3S", # TODO: mantis; add this to some config file
          :thinning => "<none>", # or device model
          :uploadBitcode => false,
          :uploadSymbols => false
      }

      filename = File.join(path, "xcodebuild_options_#{Time.now.to_i}.plist")
      Util.write_plist(filename, options)
      filename
    end

    def self.render_define_value v
      case v
        when TrueClass
          'YES'
        when FalseClass
          'NO'
        when Numeric
          v.to_s
        when String
          %{"#{v}"}
        else
          raise Exception "Unknown value type #{v}"
      end
    end

    def self.render_defines defines
      defines.map { |(k,v)| "#{k.to_s.upcase}=#{render_define_value v}" }.join " "
    end

    def self.render_option_pair pair
      k, v = pair
      maybe_v = "'#{v}'" if v
      "-#{k} #{maybe_v}"
    end

    def self.render_options options
      #TODO: validate key
      options.map { |p| self.render_option_pair p }.join " "
    end

    def self.set_plist_entry filename, key, value
      Wtf.log.info "modifying #{filename}: #{key} = #{value}"
      data = Util.read_plist(filename)
      data[key] = value
      Util.write_plist(filename, data)
    end

    def self.logname name
      "#{Stage.current_stage}_#{Time.now.to_i}.xcodebuild.#{name}.log"
    end

    def self.run action: "", options: {}, defines: nil, dir: '.', log_suffix: nil
      log_suffix ||= action.empty? ? "empty" : action

      defines ||= {}
      defines[:code_sign_identity] = "iPhone Developer" unless defines[:code_sign_identity]

      logfile = File.join(Dir.pwd, self.logname(log_suffix))

      to_run = "exec #{BIN} #{render_options options} #{render_defines defines} #{action}"

      output, status = Wooget::Util.run_cmd to_run, dir

      File.open(logfile, "w") { |f| f << output.join("\n")}

      [status, output]
    end

    def self.archive project, defines={}
      info_plist = File.join(project, "Info.plist")
      self.set_plist_entry(info_plist, "UIFileSharingEnabled", true)

      archive = File.join(project, "#{UNITY_SCHEME}.xcarchive")
      logfile = self.logname("archive")
      options = {
          :scheme => UNITY_SCHEME,
          :target => UNITY_TARGET,
          :archivePath => archive
      }
      status, stdout = self.run(action: "archive", defines: defines, options: options, dir: project)

      success = status == 0 and stdout.any? {|l| l.match(/ARCHIVE SUCCEEDED/) }
      [success, archive, logfile]
    end

    def self.export_archive project, archive, defines={}, export_options=nil
      logfile = self.logname("export_archive")
      options = {
          :exportArchive => nil,
          :archivePath => archive,
          :exportPath => project,
          :exportOptionsPlist => self.generate_options_plist(project, export_options)
      }

      status, stdout = self.run(options: options, defines: defines, dir: project, log_suffix: "export_archive")

      success = status == 0 and stdout.any? {|l| l.match(/EXPORT SUCCEEDED/) }

      ipa = File.join(project, "#{UNITY_SCHEME}.ipa")
      [success, ipa, logfile]
    end
  end
end
