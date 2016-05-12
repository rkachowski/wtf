module Wtf
  class Unity
    DEFAULT_PATH = "/Applications/Unity/Unity.app/Contents/MacOS/Unity"
    def self.run cmd
      to_run = "#{DEFAULT_PATH} -batchmode -quit #{cmd}"
      Wtf.log.info "going to run #{to_run}"

      result = `#{to_run}`
      Wtf.log.info "output: #{result}"
      result
    end
  end
end
