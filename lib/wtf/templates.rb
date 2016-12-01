module Wtf
  class Templates < Thor
    include Thor::Actions

    def self.source_root
      File.join(File.dirname(__FILE__), "templates")
    end

    no_commands do

      def android_manifest path
        self.options = Thor::CoreExt::HashWithIndifferentAccess.new.merge(self.options)

        options[:name] ||= "project"
        options[:activity] ||= "com.unity3d.player.UnityPlayerNativeActivity"
        options[:bundle_id] ||= "net.wooga.sdk.#{options[:name]}"

        Wooget.log.info "Activity - #{options[:activity]}"
        Wooget.log.info "Bundle Id / Package - #{options[:bundle_id]}"


        template("android_manifest.xml.erb", path)
      end

      def build_settings path
        self.options = Thor::CoreExt::HashWithIndifferentAccess.new.merge(self.options)
        options[:name] ||= "project"
        options[:output] ||= "/var/tmp"
        options[:bundle_id] ||= "net.wooga.sdk.#{options[:name]}"

        options[:unity_defines] ||={}
        options[:unity_defines][:ios] ||= ["CI_TESTS"]
        options[:unity_defines][:android] ||= ["CI_TESTS"]

        Wooget.log.info "Bundle Id / Package - #{options[:bundle_id]}"
        Wooget.log.info "Name - #{options[:name]}"
        Wooget.log.info "OutputDir - #{options[:output]}"
        Wooget.log.info "Android Defines - #{options[:unity_defines][:android]}"
        Wooget.log.info "iOS Defines - #{options[:unity_defines][:ios]}"

        template("build_settings.cs.erb", path)
      end

    end
  end
end
