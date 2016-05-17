module Wtf
  class BuildEditor < Stage
    def perform
      status, stdout, logfile = Unity.run "-buildTarget android" #android as sensible default for editor assembly build
      unless status == 0
        fail(Unity.failure_reason(logfile))
      end
    end
  end
end
