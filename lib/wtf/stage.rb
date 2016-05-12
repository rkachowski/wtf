module Wtf
  class Stage
    attr_reader :options


    @@current_stage = ""

    def initialize options
      @@current_stage = self.class.to_s
      @options = options
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
        msg = "Failed to start stage #{@@current_stage} - #{failure_reason}"
        if options[:no_abort]
          raise msg
        else
          abort msg
        end
      end

      perform
      teardown
    end

  end

end
