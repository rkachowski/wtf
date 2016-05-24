module Wtf
  class AndroidDeploy < Stage
    def initialize artifact_path, options={}
      super options
      @artifact_path = artifact_path
    end

    def setup
      fail "Can't find artifact at #{@artifact_path}" unless File.exists?(@artifact_path)

      `type adb`
      fail "Can't find adb in path" unless $?.exitstatus == 0

    end

    def perform
      #for all attached android devices
        #uninstall if required
        #install
        #run post install commands (broadcast shit)
    end
  end
end
