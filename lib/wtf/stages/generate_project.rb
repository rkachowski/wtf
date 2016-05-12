module Wtf
  class GenerateProject < Stage
    def setup
      #check if unity is installed
      `type /Applications/Unity/Unity.app/Contents/MacOS/Unity`
      default_path_found = $?.exitstatus == 0
      unless default_path_found
        return "Couldn't find unity installation"
      end

      nil
    end

    def perform
      Unity.run "-buildTarget '#{options[:name]}'"
    end
  end
end
