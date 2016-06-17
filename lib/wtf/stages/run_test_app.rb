module Wtf
  class RunTestApp < Stage

    TEST_RUN_TIME_SECONDS = 300

    def setup
      fail("No installed devices provided!") if options[:installed_devices].empty?
    end

    def perform
      devices = options[:installed_devices]

      states = devices.inject({}) { |hsh, d| hsh[d] = {status: :ready}; hsh }
      state_mutex = Mutex.new

      case options[:platform]
        when "android"
          threads = devices.map do |device|
            Thread.new do
              begin
                Timeout.timeout(TEST_RUN_TIME_SECONDS) do
                  run_test_app(device, state_mutex, states)
                end
              rescue Exception => e
                Wtf.log.info "!!! #{device.id} got exception #{e.message}"

                state_mutex.synchronize do
                  states[device][:status] = :error
                  states[device][:data] = {error: e.message, log: device.log.clone, platform: options[:platform]}
                end
              end
            end
          end

          threads.each { |t| t.join }
          devices.each { |d| d.detach_logcat }

          {test_result: states}
      end
    end


    def run_test_app(device, state_mutex, states)
      device.attach_logcat

      #launch app
      device.launch options[:path]
      state_mutex.synchronize { states[device][:status] = :launching }

      #wait for start tag
      WaitUtil.wait_for_condition("Test Run Start") do
        device.log_contains "[TestRunStart]"
      end
      state_mutex.synchronize { states[device][:status] = :running }
      Wtf.log.info "#{device.id} started test run"
      #wait for end tag
      WaitUtil.wait_for_condition("Test Run End", timeout_sec: TEST_RUN_TIME_SECONDS - 60) do
        device.log_contains "[TestRunEnd]"
      end
      Wtf.log.info "#{device.id} finished test run"

      device.kill options[:path]
      state_mutex.synchronize { states[device][:status] = :finished }

      #broadcast media mounted
      device.options = device.options.merge(data_uri: "file:///mnt/sdcard")
      device.broadcast "android.intent.action.MEDIA_MOUNTED"

      #grab reports
      device.pull "/sdcard/UnitTestResults.xml", "#{device.id}-results.xml"

      device.detach_logcat
      state_mutex.synchronize do
        states[device][:status] = :finished
        states[device][:data] = {results: File.open("#{device.id}-results.xml").read, log: device.log.clone}
      end
    end
  end

end

