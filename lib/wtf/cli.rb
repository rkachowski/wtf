module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    desc "Generate NAME", "Create a unity project"
    def generate name

    end
  end
end
