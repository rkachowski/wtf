require 'CFPropertyList'

module Wtf
  class XCodeBuild 
    BIN = "xcodebuild"
    UNITY_SCHEME = "Unity-iPhone"

    def self.generate_options_plist options=nil
      # TODO: check those defaults
      options ||= {
	      "compileBitcode" => false,
        #"embedOnDemandResourcesAssetPacksInBundle" => false,
	      #"iCloudContainerEnvironment" => "Development",
	      #"manifest" =>  { 
        #  "appURL" => "", 
        #  "displayImageURL" => "", 
        #  "fullSizeImageURL" => ""
        #},
	      #"method" => "Development",
	      #"onDemandResourcesAssetPacksBaseURL" => "",
	      "teamID" => "Wooga GmbH", # TODO: check this
	      #"thinning" => "<none>", # or device model
	      "uploadBitcode" => false,
	      "uploadSymbols" => false
      }
      
      filename = "xcodebuild_options_#{Time.now.to_i}.plist"

      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(options)
      plist.save(filename, CFPropertyList::List::FORMAT_XML)

      filename
    end

    def self.logname name
      "#{Stage.current_stage}_#{Time.now.to_i}.xcodebuild.#{name}"
    end

    def self.run cmd, dir='.'
      to_run = "cd #{dir}; #{BIN} #{cmd}"
      Wtf.log.info to_run

      stdout = `#{to_run}`
      [$?.exitstatus, stdout]
    end

    def self.archive project, archive="app.xcarchive"
      archive = File.join(project, archive)
      logfile = self.logname("archive")
      status, stdout = self.run "-scheme #{UNITY_SCHEME} -archivePath '#{archive}' archive > #{logfile}", project

      success = status == 0 and stdout.match(/\*\* ARCHIVE SUCCEEDED \*\*/)
      [success, archive, logfile]
    end
    
    def self.export_archive project, archive, ipa="app.ipa", options=nil
      ipa = File.join(project, ipa)
      logfile = self.logname("export_archive")
      options_plist = self.generate_options_plist(options)
      stdout, status = self.run "-exportArchive -archivePath '#{archive}' -exportPath '#{ipa}' -exportOptionsPlist '#{options_plist}' > '#{logfile}'", project

      success = status == 0 and stdout.match(/\*\* BUILD SUCCEEDED \*\*/)
      [success, ipa, logfile]
    end
  end
end
