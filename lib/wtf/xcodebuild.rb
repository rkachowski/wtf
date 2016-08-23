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
          :teamID => "YW699TVC8Z", # TODO: check this
          :thinning => "<none>", # or device model
          :uploadBitcode => false,
          :uploadSymbols => false
      }

      filename = File.join(path, "xcodebuild_options_#{Time.now.to_i}.plist")
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(options)
      plist.save(filename, CFPropertyList::List::FORMAT_XML)

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

    def self.logname name
      "#{Stage.current_stage}_#{Time.now.to_i}.xcodebuild.#{name}.log"
    end

    def self.run action: "", options: {}, defines: nil, dir: '.', log_suffix: nil
      log_suffix ||= action.empty? ? "empty" : action
      defines ||= {:code_sign_identity => "iPhone Developer"}

      logfile = File.join(Dir.pwd, self.logname(log_suffix))

      to_run = "exec #{BIN} #{render_options options} #{render_defines defines} #{action}"

      output, status = Wooget::Util.run_cmd to_run, dir

      File.open(logfile, "w") { |f| f << output.join("\n")}

      [status, output]
    end

    def self.archive project
      archive = File.join(project, "#{UNITY_SCHEME}.xcarchive")
      logfile = self.logname("archive")
      options = {
          :scheme => UNITY_SCHEME,
          :target => UNITY_TARGET,
          :archivePath => archive
      }
      status, stdout = self.run(action: "archive", options: options, dir: project)

      success = status == 0 and stdout.any? {|l| l.match(/ARCHIVE SUCCEEDED/) }
      [success, archive, logfile]
    end

    def self.export_archive project, archive, export_options=nil
      logfile = self.logname("export_archive")
      options = {
          :exportArchive => nil,
          :archivePath => archive,
          :exportPath => project,
          :exportOptionsPlist => self.generate_options_plist(project, export_options)
      }

       status, stdout = self.run(options: options, dir: project, log_suffix: "export_archive")

      success = status == 0 and stdout.any? {|l| l.match(/EXPORT SUCCEEDED/) }

      ipa = File.join(project, "#{UNITY_SCHEME}.ipa")
      [success, ipa, logfile]
    end
  end
end
