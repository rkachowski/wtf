module Wtf
  class Unity
    DEFAULT_PATH = "/Applications/Unity/Unity.app/Contents/MacOS/Unity"

    def self.logname
      "#{Stage.current_stage}_#{Time.now.to_i}.unitylog"
    end

    def self.run cmd
      run_logname = self.logname
      to_run = "#{DEFAULT_PATH} -batchmode -quit -logFile #{run_logname} #{cmd}"
      Wtf.log.info to_run

      result = `#{to_run}`
      result
    end

  end
end
