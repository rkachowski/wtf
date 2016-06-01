module Wtf
  class GenerateProject < Stage
    def setup
      #check if unity is installed
      `type /Applications/Unity/Unity.app/Contents/MacOS/Unity`
      default_path_found = $?.exitstatus == 0
      unless default_path_found
        fail("Couldn't find unity installation")
        return
      end
    end

    def perform
      exitstatus, _,logname = Unity.run "-createProject '#{File.join(options[:path], options[:name])}'"

      fail(Unity.failure_reason(logname)) unless exitstatus == 0
    end
  end
end
