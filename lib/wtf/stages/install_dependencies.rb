require 'rake' #pathmap
require 'fileutils'

module Wtf
  class InstallDependencies < Stage
    attr_reader :parent_package

    def setup

      @project = File.join(options[:path],options[:name])
      @test_package = options[:package_id]

      unless @test_package
        fail "Test package id not provided - don't know what to install to the test project"
      end

      #provided path should point to a unity project dir
      unless @project and Wooget::Util.is_a_unity_project_dir(@project)
        return fail("Couldn't find a unity project at provided path '#{@project}")
      end

      @parent_package = Util.get_parent_wooget_package @project

      unless @parent_package
        return fail("Couldn't find a parent wooget package dir in #{@project}")
      end
    end

    def perform
      copy_additional_files
      wooget_bootstrap
      set_parent_dependency

      if options[:test]
        copy_test_files
        set_unittest_dependency
      end

      Util.append_to_file File.join(@project,"paket.dependencies"), "\nnuget Wooga.SDK.Build"

      install
    end

    def set_unittest_dependency
      Util.append_to_file File.join(@project,"paket.dependencies"), "\nnuget Wooga.EAUnit"
    end

    def copy_test_files
      files = Dir[File.join(@parent_package,"tests","**/*.cs")]
      files.delete_if {|f| f =~ /AssemblyInfo/ || f =~ /TemporaryGeneratedFile/ }
      test_dir = File.join(@project, "Assets/Tests")

      Wtf.log.info "Copying test files #{files} to #{test_dir}"
      Dir.mkdir(test_dir) unless Dir.exists? test_dir
      files.each { |f| FileUtils.cp_r(f,test_dir)}
    end

    def copy_additional_files
      files = Dir[File.join(File.dirname(@project),"*")]
      files.delete @project
      Wtf.log.info "Copying files #{files} to #{@project}/Assets"
      files.each { |f| FileUtils.cp_r(f, File.join(@project, "Assets"))}
    end

    def wooget_bootstrap
      Wtf.log.info "Bootstrapping.."
      Dir.chdir(@project) do
        b = Wooget::Unity.new [], verbose:true
        b.options = b.options.merge quiet: true
        b.bootstrap
      end
    end

    def set_parent_dependency
      Util.prepend_to_file File.join(@project,"paket.dependencies"), "source #{File.expand_path(File.join(@parent_package,"bin"))}\n"
    end

    def install
      Dir.chdir(@project) do
        cli = Wooget::CLI.new [], verbose:true
        cli.install @test_package
      end
    end
  end
end
