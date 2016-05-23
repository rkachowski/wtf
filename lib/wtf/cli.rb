require 'thor/core_ext/hash_with_indifferent_access'

module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    option :test, desc: "Copy test files from parent + install test dependencies", type: :boolean, default: false
    desc "configure PACKAGE_ID [PATH] [PROJECT NAME]", "Generate project with PACKAGE_ID as dependency + install dependencies"

    def configure package_id, path=Dir.pwd, name="project"
      stages = {
          #AssertEnvironment - log attached devices, software versions, bash env, git commits etc
          GenerateProject => [{name: name, path: path}],
          InstallDependencies => [File.expand_path(File.join(path, name)), package_id, {test: options[:test]}]
      }

      stages.each { |stage, params| run_stage stage, params }
    end

    option :test, desc: "Create test scene and build with test scene as root", type: :boolean, default: false
    option :output, desc: "Artifact output path", type: :string, default: Dir.pwd
    option :bundle_id, desc: "Bundle ID / Package id to use", type: :string
    option :platform, desc: "Platform to build for", type: :string, default: "android", enum: %w(ios android)
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    desc "build", "Build artifacts"

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
          puts "yey"
      end


      #assert artifact

      stages.each { |stage, params| run_stage stage, params }
    end

    desc "run_tests", "Deploy and run artifacts on devices"

    def run_tests

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
