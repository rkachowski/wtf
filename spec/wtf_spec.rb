require_relative "../lib/wtf"
require "minitest/autorun"
include Wtf

TEST_LIB = File.join(File.dirname(__FILE__),"ExampleLib.tar.gz")
TEST_PROJ = File.join(File.dirname(__FILE__),"UnityProj.tar.gz")

describe Wtf do
  before(:all) do
    Wtf.log.level = Logger::Severity::ERROR
  end

  # it "generates a unity project" do
  #   Dir.mktmpdir do |tmpdir|
  #     Dir.chdir(tmpdir) do
  #       project_name = "TestProjectName"
  #
  #       p = GenerateProject.new name: project_name, no_abort: true
  #       p.execute
  #
  #       assert Wooget::Util.is_a_unity_project_dir(File.join(tmpdir,project_name)), "Path should be detected as a unity project dir"
  #     end
  #   end
  # end


  it "correctly bootstraps a generated project" do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        #setup example dir structure
        `tar -xzf #{TEST_LIB} `
        `tar -xzf #{TEST_PROJ} -C Wooga.SDK.Logging/unity3d/CITests`
        project_dir = File.join(tmpdir, "Wooga.SDK.Logging/unity3d/CITests/TestProject")
        bootstrapper = InstallDependencies.new(project_dir, "Wooga.SDK.Logging")

        assert_nil bootstrapper.setup, "Should setup without errors"
        assert_equal File.join(tmpdir,"Wooga.SDK.Logging"), bootstrapper.parent_package, "Should detect package dir correctly"

        bootstrapper.perform

        assert File.exists?(File.join(project_dir, "Assets/delete_me")), "Should have copied files"

        assert File.exists?(File.join(project_dir, "paket.dependencies")), "Should have wooget bootstrapped project"
        assert File.exists?(File.join(project_dir, "paket.unity3d.references")), "Should have wooget bootstrapped project"
        assert File.exists?(File.join(project_dir, "paket.lock")), "Should have wooget bootstrapped project"


        assert File.open(File.join(project_dir, "paket.dependencies")).read.include?("nuget Wooga.SDK.Logging"), "Parent package should be added as dependency"
      end
    end
  end
end

