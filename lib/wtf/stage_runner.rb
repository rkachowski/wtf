class StageRunner
  def self.run stages, stage_options
    stages.inject(nil) { |previous_stage_output, stage| run_stage stage, stage_options, previous_stage_output }

    Wtf.log.info "\n[wtf done]"

    Thread.list.each { |t| t.kill unless t == Thread.current }
    # Util.kill_zombie_children
  end

  def self.run_stage stage, params, prev_result

    stage_params = Thor::CoreExt::HashWithIndifferentAccess.new(params)
    if prev_result and prev_result.is_a?(Hash)
      stage_params.merge!(prev_result)
    end

    stage_instance = stage.new stage_params
    Wtf.log.info stage_instance.header

    begin
      result = stage_instance.execute
    rescue Exception => e
      abort "\n[wtf error]\n got exception '#{e.class}' #{e.message} - #{e.backtrace.join("\n")}"
    end

    if stage_instance.failed?
      abort stage_instance.failure_message
    end

    result
  end
end