module Wtf
  class Stage < Thor
    include Thor::Actions

    @@current_stage = ""

    def initialize
      @@current_stage = self.class.to_s
    end

    def header
      name = self.class.to_s

      "\n" +
      "#" * name.length +
      "#" + name +
      "#" * name.length +
      "\n"
    end


    def setup
      false
    end

    def perform
      "burp"
    end

    def teardown

    end

    def execute
      failure_reason = setup

      if failure_reason
        abort "Failed to start stage #{@@current_stage} - #{failure_reason}"
      end

      perform
      teardown
    end
  end

end
