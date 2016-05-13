module Wtf
  class Stage
    attr_reader :options

    @@current_stage = ""

    def self.current_stage
      @@current_stage.split(":").last
    end

    def initialize options
      @@current_stage = self.class.to_s
      @options = options
    end

    def header
      name = Wtf::Util.camel_to_spaced self.class.name

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
