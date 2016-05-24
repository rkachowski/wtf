module Wtf
  class AndroidBuild < Stage
    def setup
      required_packages = %w(Wooga.SDK.Build)
      required_packages.each do |p|
        fail("Required package #{p} not installed in project #{options[:path]}") unless Wooget::Paket.installed? options[:path], p
      end

    end

    def perform
      path = options[:path]

      manifest_path = File.join(options[:path], "Assets/Plugins/Android/AndroidManifest.xml")
      template = Templates.new [], options.clone

      unless File.exists? manifest_path
        Wtf.log.info ""
        Wtf.log.info "AndroidManifest.xml not found - generating..."

        template.android_manifest manifest_path
        Wtf.log.info ""
      end

      build_settings_path = File.join(options[:path], "Assets/Editor/WTFBuildSettings.cs")
      unless File.exists? build_settings_path
        Wtf.log.info ""
        Wtf.log.info "WTFBuildSettings.cs not found - generating..."

        template.build_settings build_settings_path
        Wtf.log.info ""
      end

      status, _, logfile = Unity.run "-buildTarget android -executeMethod Wooga.SDKBuild.Build", path

      unless status == 0
        fail(Unity.failure_reason(logfile))
        return
      end


      artifact = `ls '#{options[:output]}'/*.apk`.chomp
      unless $?.exitstatus == 0 and File.exists?(artifact)
        fail("Couldn't find build artifact (expected to find #{options[:output]}/*.apk)")
      end

      Wtf.log.info ""

      Wtf.log.info "Generated build artifact at #{artifact}"
    end
  end
end
