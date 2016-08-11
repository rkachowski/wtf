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
        Wtf.log.warn "Couldn't find a parent wooget package dir in #{@project}"
      end
    end

    def perform
      copy_additional_files
      wooget_bootstrap

      set_parent_dependency if @parent_package

      if options[:test] and @parent_package
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
      files.delete_if {|path| path.downcase == @project.downcase }

      Wtf.log.info "Copying files #{files} to #{@project}/Assets"
      files.each { |f|
        FileUtils.cp_r(f, File.join(@project, "Assets"))
      }
    end

    def wooget_bootstrap
      Wtf.log.info "Bootstrapping.."
      b = Wooget::Unity.new [], quiet: true, path:File.expand_path(@project)
      b.bootstrap
    end

    def set_parent_dependency
      dependencies_file = File.expand_path(File.join(@project,"paket.dependencies"))

      Util.prepend_to_file dependencies_file, "source #{File.expand_path(File.join(@parent_package,"bin"))}\n"
    end

    def install
      cli = Wooget::CLI.new [], verbose:true, path:File.expand_path(@project)
      cli.install @test_package
    end
  end
end
