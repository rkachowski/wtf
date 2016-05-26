require 'pry-byebug'

module Wtf
  class PryStage < Stage
    def perform
      Wtf.log.info "Gonna break!"
      binding.pry
    end
  end
end