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
        case test_result[:status]
          when :finished
            logcat = test_result[:data][:log]
            test_outcome = test_result[:data][:results]

            test_outcome.gsub!("$DEVICEID$",device.to_s.gsub(".","_"))

            File.open("#{device.id}.logcat","w") {|f| f << logcat.join}
            File.open("#{device.id}-results.xml","w") {|f| f << test_outcome}

            unit_test_reports << test_outcome
        end
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

      #todo: summarise test results to stdout

      fail "Some tests failed" if outcome == :failure or outcome == :mixed
    end

  end
end
