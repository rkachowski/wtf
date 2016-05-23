module Wtf
  class AndroidBuild < Stage
    def perform
      path = options[:path]

      puts options
      manifest_path = File.join(options[:path], "Assets/Plugins/Android/AndroidManifest.xml")
      template = Templates.new [], options.clone

      unless File.exists? manifest_path
        Wtf.log.info ""
        Wtf.log.info "AndroidManifest not found - generating default file (these values may be overridden by unity)"

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

      status, stdout, logfile = Unity.run "-buildTarget android -executeMethod Wooga.SDKBuild.Build", path
      unless status == 0
        fail(Unity.failure_reason(logfile))
      end
    end
  end
end
