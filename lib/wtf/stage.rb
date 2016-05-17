module Wtf
  class Stage
    attr_reader :options, :failure_message
    @@current_stage = ""

    def self.current_stage
      @@current_stage.split(":").last
    end

    def initialize options
      @@current_stage = self.class.to_s
      @options = options
      @failure_message = ""
    end

    def verbose
      options[:verbose]
    end

    def header
      name = stage_name

      "\n" +
      "##" * name.length + "\n" +
      "# " + name + "\n" +
      "##" * name.length + "\n" +
      "\n"
    end

    def stage_name
      Wtf::Util.camel_to_spaced self.class.name.split(":").last
    end

    def setup

    end

    def perform

    end

    def teardown

    end

    def failed?
      not @failure_message.empty?
    end

    def fail msg
      method_name = caller_locations(1,1)[0].label

      @failure_message = "[wtf failure] #{stage_name} #{method_name.capitalize} failed - #{msg}"
    end

    def execute
      setup
      perform unless failed?
      teardown unless failed?
    end

  end

end
