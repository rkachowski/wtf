require 'thor/core_ext/hash_with_indifferent_access'

module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    option :test, desc: "Copy test files from parent + install test dependencies", type: :boolean, default: false
    desc "make_test_project PACKAGE_ID [PATH] [PROJECT NAME]", "Generate project with PACKAGE_ID as dependency + install dependencies"

    def make_test_project package_id, path=Dir.pwd, name="project"
      stages = {
          SetupAndAssertEnvironment =>[{}],
          GenerateProject => [{name: name, path: path}],
          InstallDependencies => [File.expand_path(File.join(path, name)), package_id, {test: options[:test]}]
      }

      run_stages stages
    end

    option :test, desc: "Create test scene and build with test scene as root", type: :boolean, default: false
    option :output, desc: "Artifact output path", type: :string, default: Dir.pwd
    option :bundle_id, desc: "Bundle ID / Package id to use", type: :string
    option :platform, desc: "Platform to build for", type: :string, default: "android", enum: %w(ios android)
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    desc "build", "Build artifacts for project (.apk / .app)"

    def build
      stages = {}
      stages[BuildEditor] = [options]
      stages[CreateTestScene] = [options] if options[:test]

      case options[:platform]
        when "android"
          bundle_id = options[:bundle_id] || "net.wooga.sdk.#{options[:name]}"
          build_options = options.merge({:bundle_id => bundle_id})

          stages[AndroidBuild] = [Thor::CoreExt::HashWithIndifferentAccess.new(build_options)]
        when "ios"
          puts "not implemented"
      end

      run_stages stages
    end

    desc "deploy_and_run", "Deploy and run test artifacts on devices"

    option :path, desc: "Path to artifact", required: true, type: :string
    option :platform, desc: "Platform to deploy to", type: :string, required: true, enum: %w(ios android)
    def deploy_and_run
      stages = {}

      stages[FindDevices] = [options]
      stages[InstallApp] = [options]
      stages[PostInstall] = [options]
      stages[RunTestApp] = [options]
      stages[FinalizeResults] = [options]
      #stages[PryStage] = [options]


      case options[:platform]
        when "android"

        when "ios"
          puts "not implemented"
      end

      #install
      #run tests
      #post run
      #grab results
      #collate

      run_stages stages
    end

    no_commands do

      def run_stages stages
        stages.inject(nil) { |previous_stage_output, (stage, params)| run_stage stage, params, previous_stage_output }

        Wtf.log.info "\n[wtf done]"
      end

      def run_stage stage, params, prev_result

        #if the previous stage returned a hash, and the next stage accepts a hash as it's last parameter,
        # then we will merge the previous result with the input to the next stage
        if prev_result and prev_result.is_a?(Hash) and params.last.is_a?(Hash)
          merged_parameters = Thor::CoreExt::HashWithIndifferentAccess.new(params.last)
          merged_parameters.merge!(prev_result)
          params[params.length - 1] = merged_parameters
        end

        stage_instance = stage.new *params
        Wtf.log.info stage_instance.header

        begin
          result = stage_instance.execute
        rescue Exception => e
          abort "\n[wtf error]\n got exception '#{e.class}' #{e.message} - #{e.backtrace.join("\n")}"
        end

        if stage_instance.failed?
          abort stage_instance.failure_message
        end

        result
      end
    end
  end
end
