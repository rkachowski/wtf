require 'erb'

module Wtf
  class FinalizeResults < Stage
    def setup
      fail "Test results not provided" unless options[:test_result]
    end


    def perform
      statuses = options[:test_result].values.map{|d|d[:status]}

      #test run outcome - not test result outcome
      outcome = :unknown

      outcome = :mixed if statuses.any? {|s| s == :finished }
      outcome = :success if statuses.all? {|s| s == :finished }
      outcome = :failure if statuses.all? {|s| s == :error }

      if outcome == :unknown
        Wtf.log.info "Unknown test result - #{statuses}"
      else
        Wtf.log.info "Test run outcome: #{outcome}"
      end

      unit_test_reports = []

      options[:test_result].each do |device, test_result|
        logcat = test_result[:data][:log]
        File.open("#{device.id}.logcat","w") {|f| f << logcat.join} if logcat

        case test_result[:status]
          when :finished
            test_outcome = test_result[:data][:results]
            test_outcome.gsub!("$DEVICEID$",device.to_s.gsub(".","_"))

            File.open("#{device.id}-results.xml","w") {|f| f << test_outcome}

            unit_test_reports << test_outcome
          when :error
            error_report = error_report_for_device(device, test_result)

            File.open("#{device.id}-results.xml","w") {|f| f << error_report}

            unit_test_reports << error_report
        end

        device.power if options[:plaform] == "android" and device.screen_active?
      end

      Wtf.log.info("Got #{unit_test_reports.length} test results, merging..")

      #merge those results
      results = Dir["*-results.xml"].map { |f| Nokogiri::XML(File.open(f).read) }
      suite_nodes = results.map {|r| r.xpath("//testsuite")}
      doc = Nokogiri::XML("<testsuites></testsuites>")
      suite_nodes.each { |n| doc.at("testsuites").add_child(n) }

      filename = options[:path].split(".").first+"-UnitTestResults.xml"

      Wtf.log.info "Writing results to #{filename}"
      File.open(filename,"w"){|f| f << doc.to_xml }

      #todo: summarise unit_test_reports to stdout
    end

    def error_report_for_device(device, test_result)
      props = {case_name: "TestError",
               platform: test_result[:data][:platform].capitalize,
               device: device.to_s.gsub(".", "_"),
               error_message: "Device failed to complete tests: '#{test_result[:data][:error]}'"}

      erb_file = File.join(File.dirname(__FILE__), "..", "templates", "jenkins_junit_error.xml.erb")
      ERB.new(File.open(erb_file).read).result(binding)
    end

  end
end
