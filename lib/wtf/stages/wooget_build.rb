module Wtf
  class WoogetBuild < Stage
    def setup
      @package_dir = Util.get_parent_wooget_package options[:path]
      fail "Couldn't find a parent package dir in #{options[:path]}" unless @package_dir

      #default high number for version testing
      #todo: don't allow push with this number
      @options[:version_number] ||= "919.919.919"
    end

    def perform
      #install dependencies
      wooget = Wooget::CLI.new [], path:@package_dir, verbose:true

      #build
      Wtf.log.info "Building local package #{options[:version_number]} to #{@package_dir}/bin "
      wooget.invoke "build",[], version:options[:version_number], output:File.join(@package_dir,"bin"), native:false, path:@package_dir
    end
  end
end
