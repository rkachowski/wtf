require 'fileutils'

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
      project_path = File.join(options[:path], options[:name])
      FileUtils.mkdir_p(project_path) unless Dir.exists? File.dirname(project_path)

      if Wooget::Util.is_a_unity_project_dir(project_path)
        Wtf.log.info "Existing project detected at #{project_path} - cleaning..."
        FileUtils.rmtree(project_path)
      end

      exitstatus, _,logname = Unity.run "-createProject '#{project_path}'"

      fail(Unity.failure_reason(logname)) unless exitstatus == 0
    end
  end
end
