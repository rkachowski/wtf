module Wtf
  class CLI < Thor
    include Thor::Actions
    add_runtime_options!

    desc "generate NAME", "Create a unity project"
    def generate name
      p = GenerateProject.new name:name
      p.execute
    end
  end
end
