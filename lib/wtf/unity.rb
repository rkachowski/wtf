module Wtf
  class Unity
    #todo: change this via uvm support
    DEFAULT_PATH = "/Applications/Unity/Unity.app/Contents/MacOS/Unity"

    def self.logname
      "#{Stage.current_stage}_#{Time.now.to_i}.unitylog"
    end

    def self.run cmd, path="."
      run_logname = self.logname
      to_run = "#{DEFAULT_PATH} -batchmode -quit -logFile #{run_logname} -projectPath #{File.expand_path(path)} #{cmd}"
      Wtf.log.info to_run

      result = `#{to_run}`
      [$?.exitstatus, result, run_logname]
    end

    def self.failure_reason logfile
      log = File.open(logfile).read.lines

      compile_failure_start = log.find_index { |l| l =~ /compilationhadfailure: True/ }
      return get_compile_fail(log, compile_failure_start) if compile_failure_start

      arbitrary_batch_mode_fail = log.find_index { |l| l =~ /Aborting batchmode due to failure/ }
      return get_arbitrary_failure(log, arbitrary_batch_mode_fail) if arbitrary_batch_mode_fail

      #unknown failure
      "Unknown failure - check #{logfile} for detail"
    end

    def self.get_arbitrary_failure(log, arbitrary_batch_mode_fail)
      error = log.slice(arbitrary_batch_mode_fail..-1)
      failure_end = error.find_index { |l| l =~ /^\s*$/ }
      msg = error.slice(0,failure_end)
      msg.shift
      msg.join
    end

    def self.get_compile_fail(log, compile_failure_start)
      error = log.slice(compile_failure_start..-1)
      failure_end = error.find_index { |l| l =~ /EndCompilerOutput/ }
      msg = error.slice(0,failure_end)
      msg.shift
      msg.join
    end
  end
end
