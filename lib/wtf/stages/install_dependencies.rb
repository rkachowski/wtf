require 'rake' #pathmap

module Wtf
  class InstallDependencies < Stage
    attr_reader :parent_dir

    def setup
      #provided path should point to a unity project dir
      unless options[:project] and Wooget::Util.is_a_unity_project_dir(options[:project])
        return "Couldn't find a unity project at provided path '#{options[:project]}"
      end

      #there should be a wooget package dir in a parent dir
      options[:project].length.times do |i|
        path_comp = options[:project].pathmap("%#{i}d")
        if Wooget::Util.is_a_wooget_package_dir path_comp
          @parent_dir = path_comp
          break
        end
      end

      unless @parent_dir
        return "Couldn't find a parent wooget package dir in #{options[:project]}"
      end

      nil
    end

    def perform
      #bootstrap project
      #copy dependencies from parent
      #install
      #copy tests from parent
      #get additional assets
    end
  end
end
