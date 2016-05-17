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
      [$?.exitstatus, result, run_logname]
    end

    def self.failure_reason logfile
      log = File.open(logfile).read.lines
      failure_start = log.find_index { |l| l =~ /compilationhadfailure: True/ }
      error = log.slice(failure_start..-1)
      failure_end = error.find_index { |l| l =~ /EndCompilerOutput/ }
      error.slice(0,failure_end).shift.join
    end
  end
end
