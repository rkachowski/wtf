module Wtf
  class BuildEditor < Stage
    def perform
      #android as sensible default for editor assembly build
      platform = options[:platform] || "android"
      path = options[:path]

      status, _, logfile = Unity.run "-buildTarget #{platform}", path, platform
      failure = Unity.failure_reason(logfile)
      failure ||= "Unknown failure - check #{logfile} for detail" if status != 0
      fail(failure) if failure
    end
  end
end
