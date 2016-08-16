require 'thor/core_ext/hash_with_indifferent_access'
require 'httpclient'
require 'json'
module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    option :test, desc: "Copy test files from parent + install test packages", type: :boolean, default: false
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    option :package_id, desc: "Id of the package you want to create a test project for", required: true
    option :build, desc: "Should do a wooget build of local package", type: :boolean, default: true
    desc "make_test_project", "Generate project with package_id as dependency + install dependencies"

    def make_test_project
      stages = [
          SetupAndAssertEnvironment,
          WoogetBuild,
          GenerateProject,
          InstallDependencies
      ]

      stages.delete WoogetBuild unless options[:build]

      run_stages stages, options
    end

    desc "ci_setup", "make_test_project for ci"
    option :test, desc: "Copy test files from parent + install test packages", type: :boolean, default: true
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    option :package_id, desc: "Id of the package you want to create a test project for", required: true
    def ci_setup
      invoke "make_test_project", [],  test:true, name: options[:name], path: options[:path], package_id:options[:package_id ]
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
      stages = [FindDevices,InstallApp, PostInstall, RunTestApp, FinalizeResults]

      run_stages stages, options
    end

    option :branch, desc: "branch this job will run upon", default: "master"
    option :package_id, desc: "id of the package to build",  required: true
    option :project_path, desc: "path where the unity project will be generated and built",  default:"unity3d/citest"
    desc "jenkinsfile", "generate a jenkinsfile for the ci"
    def jenkinsfile
      props = options.clone

      template_path = File.join(File.dirname(__FILE__), "templates","Jenkinsfile.erb")
      File.open("Jenkinsfile","w") { |f| f << ERB.new(File.open(template_path).read).result(binding) }
    end

    option :secret, desc: "you sit on it, but don't take it with you", type: :string
    desc "sdkbot ROOM MESSAGE","make sdk bot say something to a room"
    def sdkbot room, message
      secret = options[:secret] || ENV["SDKBOT_SECRET"]
      msg =  HTTPClient.post("https://sdk-bot.herokuapp.com/sdk/announce", {room: room, message: message, secret:secret}.to_json,{ 'Content-Type' => 'application/json'})
      puts msg.body
    end

    no_commands do

      def run_stages stages, stage_options
        stages.inject(nil) { |previous_stage_output, stage| run_stage stage, stage_options, previous_stage_output }

        Wtf.log.info "\n[wtf done]"

        Thread.list.each { |t| t.kill unless t == Thread.current }
        # Util.kill_zombie_children
      end

      def run_stage stage, params, prev_result

        stage_params = Thor::CoreExt::HashWithIndifferentAccess.new(params)
        if prev_result and prev_result.is_a?(Hash)
          stage_params.merge!(prev_result)
        end

        stage_instance = stage.new stage_params
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
