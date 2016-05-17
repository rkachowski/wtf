require 'rake' #pathmap
require 'fileutils'

module Wtf
  class InstallDependencies < Stage
    attr_reader :parent_package

    def initialize project, test_package, options={}
      super options

      @project = project
      @test_package = test_package
    end

    def setup
      #provided path should point to a unity project dir
      unless @project and Wooget::Util.is_a_unity_project_dir(@project)
        return fail("Couldn't find a unity project at provided path '#{@project}")
      end

      #there should be a wooget package dir in a parent dir
      @project.length.times do |i|
        path_comp = @project.pathmap("%#{i}d")
        if Wooget::Util.is_a_wooget_package_dir path_comp
          Wtf.log.info "Found parent package dir at #{path_comp}"
          @parent_package = path_comp
          break
        end
      end

      unless @parent_package
        return fail("Couldn't find a parent wooget package dir in #{@project}")
      end
    end

    def perform
      copy_additional_files
      wooget_bootstrap
      set_parent_dependency

      if options[:test]
        #copy tests from parent
        #add test package dep
      end
      if verbose
        #log dependencies
      end
      install
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
        b = Wooget::Unity.new
        b.options = b.options.merge quiet: true
        b.bootstrap
      end
    end

    def set_parent_dependency
      Util.prepend_to_file File.join(@project,"paket.dependencies"), "source #{File.join(@parent_package,"bin")}\n"
    end

    def install
      Dir.chdir(@project) do
        cli = Wooget::CLI.new
        cli.install @test_package
      end
    end
  end
end