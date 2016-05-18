module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    option :test, desc: "Copy test files from parent + install test dependencies", type: :boolean, default: false
    desc "configure PACKAGE_ID [PROJECT NAME]","Generate project + install dependencies"
    def configure package_id, path=Dir.pwd, name="project"
      stages = {
          GenerateProject => [{name:name, path:path}],
          InstallDependencies => [File.expand_path(File.join(path,name)), package_id, {test:options[:test]}]
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
