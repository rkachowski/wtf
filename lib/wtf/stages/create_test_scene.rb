module Wtf
  class CreateTestScene < Stage
    def setup
      required_packages = %w(Wooga.EAUnit)
      required_packages.each do |p|
        fail("Required package #{p} not installed in project #{options[:path]}") unless Wooget::Paket.installed? options[:path], p
      end
    end

    def perform
      platform = options[:platform] || "android"
      path = options[:path]

      status, stdout, logfile = Unity.run "-buildTarget #{platform} -executeMethod EAUnit.Editor.Setup", path
      unless status == 0
        fail(Unity.failure_reason(logfile))
      end
    end
  end
end
