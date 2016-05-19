module Wtf
  class BuildEditor < Stage
    def perform
      #android as sensible default for editor assembly build
      platform = options[:platform] || "android"
      path = options[:path]

      status, stdout, logfile = Unity.run "-buildTarget #{platform}", path
      unless status == 0
        fail(Unity.failure_reason(logfile))
      end
    end
  end
end
