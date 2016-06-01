require 'thor/core_ext/hash_with_indifferent_access'

module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    option :test, desc: "Copy test files from parent + install test packages", type: :boolean, default: false
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    option :package_id, desc: "Id of the package you want to create a test project for", required: true
    desc "make_test_project", "Generate project with package_id as dependency + install dependencies"

    def make_test_project

      stages = [
          SetupAndAssertEnvironment,
          GenerateProject,
          InstallDependencies
      ]

      run_stages stages, options
    end

    option :test, desc: "Create test scene and build with test scene as root", type: :boolean, default: false
    option :output, desc: "Artifact output path", type: :string, default: Dir.pwd
    option :bundle_id, desc: "Bundle ID / Package id to use", type: :string
    option :platform, desc: "Platform to build for", type: :string, default: "android", enum: %w(ios android)
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    desc "build", "Build artifacts for project (.apk / .app)"

    def build
      stages = [BuildEditor]
      stages << CreateTestScene if options[:test]

      case options[:platform]
        when "android"
          stages << AndroidBuild
        when "ios"
          puts "not implemented"
      end

      run_stages stages, options
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

      run_stages stages, options
    end

    no_commands do

      def run_stages stages, stage_options
        stages.inject(nil) { |previous_stage_output, stage| run_stage stage, stage_options, previous_stage_output }

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

        stage_instance = stage.new Thor::CoreExt::HashWithIndifferentAccess.new(params)
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
