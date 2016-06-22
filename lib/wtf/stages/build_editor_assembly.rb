module Wtf
  class BuildEditor < Stage
    def perform
      #android as sensible default for editor assembly build
      platform = options[:platform] || "android"
      path = options[:path]

      status, stdout, logfile = Unity.run "-buildTarget #{platform}", path
      failure = Unity.failure_reason(logfile)
      failure ||= "Unknown failure - check #{logfile} for detail" if status != 0
      fail(failure) if failure
    end
  end
end
