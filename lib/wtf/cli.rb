module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    desc "configure PACKAGE_ID [PROJECT NAME]","Generate project + install dependencies"
    def configure package_id, name="CITests"
      stages = {
          GenerateProject => [{name:name}],
          InstallDependencies => [File.join(Dir.pwd,name), package_id, {}]
      }

      stages.each {|stage, params| run_stage stage, params }
    end

    no_commands do


      def run_stage stage, params
        stage_instance = stage.new *params
        Wtf.log.info stage_instance.header
        stage_instance.execute
        if stage_instance.failed?
          abort stage_instance.failure_message
        end
      end
    end
  end
end
