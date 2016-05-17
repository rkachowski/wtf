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
      exitstatus, log = Unity.run "-createProject '#{options[:name]}'"

      fail(log) unless exitstatus == 0
    end
  end
end
