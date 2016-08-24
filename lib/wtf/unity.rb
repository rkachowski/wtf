module Wtf
  class Unity
    #todo: change this via uvm support
    DEFAULT_PATH = "/Applications/Unity/Unity.app/Contents/MacOS/Unity"

    def self.logname(platform=nil)
      "#{Stage.current_stage}_#{platform}_#{Time.now.to_i}.unitylog"
    end

    def self.run cmd, path=".", platform=nil
      run_logname = self.logname(platform)
      to_run = "#{DEFAULT_PATH} -batchmode -quit -logFile #{run_logname} -projectPath #{File.expand_path(path)} #{cmd}"
      Wtf.log.info to_run

      stdout = `#{to_run}`
      result = [$?.exitstatus, stdout, run_logname]

      Wtf.log.info "Command returned exit code #{result[0]}"

      #unity logfile needs to flush...
      sleep 0.2

      result
    end

    def self.failure_reason logfile
      log = File.open(logfile).read.lines

      compile_failure_start = log.find_index { |l| l =~ /compilationhadfailure: True/ }
      return get_compile_fail(log, compile_failure_start) if compile_failure_start

      arbitrary_batch_mode_fail = log.find_index { |l| l =~ /Aborting batchmode due to failure/ }
      return get_arbitrary_failure(log, arbitrary_batch_mode_fail) if arbitrary_batch_mode_fail

      clashing_plugin = log.find_index { |l| l =~ /Found plugins with same names and architectures/ }
      return log[clashing_plugin] if clashing_plugin

      #unknown failure
      nil#"Unknown failure - check #{logfile} for detail"
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

    def self.xcode_project_path logfile
      log = File.open(logfile).read
      match = log.match(/Building .* for iOS to (.*.proj)/)
      match[1] if match
    end
  end
end
