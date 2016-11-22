require 'thor/core_ext/hash_with_indifferent_access'
require 'httpclient'
require 'json'
module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!



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
    option :file, desc: "A file to attach, will be appended to the message in a code block"
    desc "sdkbot ROOM MESSAGE","make sdk bot say something to a room"
    def sdkbot room, message
      secret = options[:secret] || ENV["SDKBOT_SECRET"]

      message = message.dup
      if options[:file] and File.exists? options[:file]
        message << "\n```\n"
        message << File.open(options[:file]).read
        message << "\n```\n"
      end
      msg =  HTTPClient.post("https://sdk-bot.herokuapp.com/sdk/announce", {room: room, message: message, secret:secret}.to_json,{ 'Content-Type' => 'application/json'})
      puts msg.body
    end


    ## device helper methods
    ## todo: unscrew this duplication
    option :clean, desc: "Uninstall the app if it exists already?", type: :boolean, default: true
    desc "install FILE", "installs the app provided"
    def install file
      abort "Unrecognised file  '#{file}' - must be an apk or ipa file " unless file.end_with?("apk") or file.end_with?("ipa")

      case
        when file.end_with?("apk")
          #android install
          devices = Android.all options[:clean]
          threads = devices.map { |d| Thread.new{ d.install(file)} }
          threads.each {|t| t.join }

        when file.end_with?("ipa")
          #iphone install
      end
    end

    desc "uninstall FILE", "uninstalls the app provided"
    def uninstall file
      abort "Unrecognised file  '#{file}' - must be an apk or ipa file " unless file.end_with?("apk") or file.end_with?("ipa")

      case
        when file.end_with?("apk")
          #android install
          devices = Android.all options[:clean]
          threads = devices.map { |d| Thread.new{ d.uninstall(file)} }
          threads.each {|t| t.join }

        when file.end_with?("ipa")
          #iphone install
      end
    end

    desc "launch FILE", "launches the app from the file"
    def launch file
      abort "Unrecognised file  '#{file}' - must be an apk or ipa file " unless file.end_with?("apk") or file.end_with?("ipa")

      case
        when file.end_with?("apk")

          devices = Android.all
          devices.each { |d|  d.launch(file)}

        when file.end_with?("ipa")

      end
    end

    desc "stop FILE", "kills the app from the file"
    def stop file
      abort "Unrecognised file  '#{file}' - must be an apk or ipa file " unless file.end_with?("apk") or file.end_with?("ipa")

      case
        when file.end_with?("apk")

          devices = Android.all
          devices.each { |d|  d.kill(file)}

        when file.end_with?("ipa")

      end
    end

  end
end
