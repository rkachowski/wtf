module Wtf
  class RunTestApp < Stage

    TEST_RUN_TIME_SECONDS = 300

    def setup
      fail("No installed devices provided!") if options[:installed_devices].empty?
    end

    def perform
      devices = options[:installed_devices]

      states = devices.inject({}) { |hsh, d| hsh[d] = { :status => :ready }; hsh }
      state_mutex = Mutex.new

      threads = devices.map do |device|
        Thread.new do
          begin
            test_run_time = TEST_RUN_TIME_SECONDS
            test_run_time *= 2 unless is_android

            Timeout.timeout(test_run_time) do
              run_test_app(device, state_mutex, states)
            end
          rescue Exception => e
            Wtf.log.info "!!! #{device.id} got exception #{e.message}"

            state_mutex.synchronize do
              states[device][:status] = :error
              states[device][:data] = { error: e.message, log: device.log.clone, platform: options[:platform] }
            end
          end
        end
      end

      threads.each { |t| t.join }
      devices.each { |d| d.detach_log }

      failed_devices = options[:errored_devices] || {}
      { :test_result => states.merge(failed_devices) }
    end

    def run_test_app(device, state_mutex, states)
      is_android = options[:platform] == "android"
      device.attach_log if is_android

      # launch app
      bundle_id = device.launch(options[:path])
      state_mutex.synchronize { states[device][:status] = :launching }

      # wait for start tag
      test_run_time = TEST_RUN_TIME_SECONDS
      test_run_time *= 2 unless is_android

      WaitUtil.wait_for_condition("Test Run Start", timeout_sec: test_run_time * 0.1) do
        device.log_contains "[TestRunStart]", bundle_id: bundle_id
      end
      state_mutex.synchronize { states[device][:status] = :running }
      Wtf.log.info "#{device.id} started test run"
      # wait for end tag
      WaitUtil.wait_for_condition("Test Run End", timeout_sec: test_run_time * 0.9) do
        device.log_contains "[TestRunEnd]", bundle_id: bundle_id
      end
      Wtf.log.info "#{device.id} finished test run"

      device.kill options[:path]
      state_mutex.synchronize { states[device][:status] = :finished }

      # grab reports
      if is_android
        device.detach_log 

        #broadcast media mounted
        device.options = device.options.merge(data_uri: "file:///mnt/sdcard")
        device.broadcast "android.intent.action.MEDIA_MOUNTED"

        device.pull "/sdcard/UnitTestResults.xml", "#{device.id}-results.xml"
      else
        device.pull "UnitTestResults.xml", "#{device.id}-results.xml", bundle_id: bundle_id
      end

      state_mutex.synchronize do
        endlog = is_android ? device.log : device.log(bundle_id: bundle_id)

        states[device][:status] = :finished
        states[device][:data] = {
          results: File.open("#{device.id}-results.xml").read, 
          log: endlog.clone
        }
      end
    end
  end

end

