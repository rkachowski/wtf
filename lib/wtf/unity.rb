module Wtf
  class Unity
    DEFAULT_PATH = "/Applications/Unity/Unity.app/Contents/MacOS/Unity"
    def self.run cmd
      to_run = "#{DEFAULT_PATH} -batchmode -quit #{cmd}"
    end
  end
end
