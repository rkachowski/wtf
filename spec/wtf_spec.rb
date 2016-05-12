require_relative "../lib/wtf"
require "minitest/autorun"
include Wtf

describe Wtf do
  before(:all) do
    Wtf.log.level = Logger::Severity::ERROR
  end

  it "generates a unity project" do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        project_name = "TestProjectName"

        p = GenerateProject.new name: project_name, no_abort: true
        p.execute

        assert Wooget::Util.is_a_unity_project_dir(File.join(tmpdir,project_name)), "Path should be detected as a unity project dir"
      end
    end
  end
end

