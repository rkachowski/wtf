module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    option :test, desc: "Copy test files from parent + install test dependencies", type: :boolean, default: false
    desc "configure PACKAGE_ID [PATH] [PROJECT NAME]","Generate project with PACKAGE_ID as dependency + install dependencies"
    def configure package_id, path=Dir.pwd, name="project"
      stages = {
          #AssertEnvironment - log attached devices, software versions, bash env, git commits etc
          GenerateProject => [{name:name, path:path}],
          InstallDependencies => [File.expand_path(File.join(path,name)), package_id, {test:options[:test]}]
      }

      stages.each {|stage, params| run_stage stage, params }
    end

    option :test, desc: "Create test scene and build with test scene as root", type: :boolean, default: false
    desc "build PATH [PLATFORM]","Build artifacts"
    def build path=Dir.pwd, platform="android"
      stages = {
          BuildEditor => [{platform:platform, path:path}]#,
          #CreateTestScene
          #ApplyBuildSettings
          #BuildTarget
      }

      stages.each {|stage, params| run_stage stage, params }
    end

    desc "run", "Deploy and run artifacts on devices"
    def run

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
