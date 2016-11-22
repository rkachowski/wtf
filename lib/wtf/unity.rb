module Wtf
  class Unity < Thor
    DEFAULT_PATH = "/Applications/Unity/Unity.app/Contents/MacOS/Unity"

    #
    # Utility Functions
    #

    def self.logname(platform=nil)
      "#{Stage.current_stage}_#{platform}_#{Time.now.to_i}.unitylog"
    end

    def self.run cmd, path=".", platform=nil
      run_logname = self.logname(platform)
      to_run = "#{DEFAULT_PATH} -batchmode -quit -logFile #{run_logname} -projectPath #{File.expand_path(path)} #{cmd}"
      Wtf.log.info to_run

      stdout = `#{to_run}`
      result = [$?.exitstatus, stdout, run_logname]

      Wtf.log.info "Command returned exit code #{result[0]}"

      #unity logfile needs to flush...
      sleep 0.2

      result
    end

    def self.failure_reason logfile
      log = File.open(logfile).read.lines

      compile_failure_start = log.find_index { |l| l =~ /compilationhadfailure: True/ }
      return get_compile_fail(log, compile_failure_start) if compile_failure_start

      arbitrary_batch_mode_fail = log.find_index { |l| l =~ /Aborting batchmode due to failure/ }
      return get_arbitrary_failure(log, arbitrary_batch_mode_fail) if arbitrary_batch_mode_fail

      clashing_plugin = log.find_index { |l| l =~ /Found plugins with same names and architectures/ }
      return log[clashing_plugin] if clashing_plugin

      #unknown failure
      nil#"Unknown failure - check #{logfile} for detail"
    end


    def self.get_arbitrary_failure(log, arbitrary_batch_mode_fail)
      error = log.slice(arbitrary_batch_mode_fail..-1)
      failure_end = error.find_index { |l| l =~ /^\s*$/ }
      msg = error.slice(0,failure_end)
      msg.shift
      msg.join
    end

    def self.get_compile_fail(log, compile_failure_start)
      error = log.slice(compile_failure_start..-1)
      failure_end = error.find_index { |l| l =~ /EndCompilerOutput/ }
      msg = error.slice(0,failure_end)
      msg.shift
      msg.join
    end

    def self.xcode_project_path logfile
      log = File.open(logfile).read
      match = log.match(/Building .* for iOS to (.*.proj)/)
      match[1] if match
    end

    #
    # Thor Tasks
    #

    option :test, desc: "Copy test files from parent + install test packages", type: :boolean, default: false
    option :name, desc: "App name", type: :string, default: "project"
    option :path, desc: "Path to unity project", required: true, type: :string
    option :package_id, desc: "Id of the package you want to create a test project for", required: true
    option :build, desc: "Do a wooget build of local package?", type: :boolean, default: true
    desc "create_project", "Generate project with package_id as dependency + install dependencies"

    def create_project
      stages = [
          SetupAndAssertEnvironment,
          WoogetBuild,
          GenerateProject,
          InstallDependencies
      ]

      stages.delete WoogetBuild unless options[:build]

      StageRunner.run stages, options
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

      build_stage = options[:platform] == "android" ? AndroidBuild : IOSBuild
      stages << build_stage

      run_stages stages, options
    end

    desc "run", "Deploy and run test artifacts on devices"
    option :path, desc: "Path to artifact", required: true, type: :string
    option :platform, desc: "Platform to deploy to", type: :string, required: true, enum: %w(ios android)
    def run
      stages = [FindDevices, InstallApp, PostInstall, RunTestApp, FinalizeResults]

      run_stages stages, options
    end
  end
end
