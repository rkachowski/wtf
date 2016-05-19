module Wtf
  class CreateTestScene < Stage
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
