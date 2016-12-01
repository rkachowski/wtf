module Wtf
  class IOSBuild < Stage
    def setup
      required_packages = %w(Wooga.SDK.Build)
      required_packages.each do |p|
        fail("Required package #{p} not installed in project #{options[:path]}") unless Wooget::Paket.installed? options[:path], p
      end

      options[:bundle_id] ||= "net.mantisshrimp.sdk-testapp"
    end

    def perform
      path = options[:path]

      template = Templates.new [], options.clone

      build_settings_path = File.join(options[:path], "Assets/Editor/WTFBuildSettings.cs")
      unless File.exists? build_settings_path
        Wtf.log.info ""
        Wtf.log.info "WTFBuildSettings.cs not found - generating..."

        template.build_settings build_settings_path
        Wtf.log.info ""
      end

      # unity -> xcode
      status, _, logfile = Unity.run "-buildTarget ios -executeMethod Wooga.SDKBuild.Build", path, "ios"

      failure = Unity.failure_reason(logfile)
      failure ||= "Unknown failure - check #{logfile} for detail" if status != 0
      fail(failure) if failure

      project = Unity.xcode_project_path(logfile)
      Wtf.log.info "XCode project at '#{project}'"
      check_artifact "XCode project", project

      defines = {}
      if options[:defines]
        values = options[:defines].split(";").map{ |s| s.split("=") }
        values.each { |(k,v)| defines[k] = v }
      end

      # xcode -> xcarchive
      success, xcarchive, logfile = XCodeBuild.archive(project, defines)
      fail("xcodebuild failure - check '#{logfile}'") unless success
      check_artifact("XCArchive file", xcarchive)

      # archive -> ipa
      success, ipa, logfile = XCodeBuild.export_archive(project, xcarchive, defines)
      fail("xcodebuild failure - check '#{logfile}'") unless success
      check_artifact("IPA package", ipa)
    end

    def check_artifact name, artifact
      fail("nil artifacts don't exist") unless artifact
      fail("Couldn't find #{name} (expected to find '#{artifact}'") unless File.exists?(artifact)

      Wtf.log.info "Generated #{name} at '#{artifact}'"
      Wtf.log.info ""

      artifact
    end
  end
end
