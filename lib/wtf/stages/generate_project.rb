module Wtf
  class GenerateProject < Stage
    def setup
      #check if unity is installed
      `type /Applications/Unity/Unity.app/Contents/MacOS/Unity`
      default_path_found = $?.exitstatus == 0
      unless default_path_found
        return fail("Couldn't find unity installation")
      end

      nil
    end

    def perform
      Unity.run "-createProject '#{options[:name]}'"
    end
  end
end
