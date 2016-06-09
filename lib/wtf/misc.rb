module Wtf
  module Util
    def self.is_available_in_env? prog
      `type "#{prog}"`
      $?.exitstatus == 0
    end

    def self.get_parent_wooget_package path
      path = File.expand_path(path)

      path.length.times do |i|
        path_comp = path.pathmap("%#{i}d")
        if Wooget::Util.is_a_wooget_package_dir path_comp
          return path_comp
        end
      end

      nil
    end

    class FileManip < Thor
      include Thor::Actions
      add_runtime_options!
    end

    @@file_manip = FileManip.new [], quiet:true

    def self.camel_to_spaced str
      cpy = str.clone

      match_offsets = cpy.to_enum(:scan, /[a-z][A-Z]/).map {Regexp.last_match.begin(0)}
      match_offsets.each_with_index { |o,i| cpy.insert(o+i+1," ") }
      cpy
    end

    def self.prepend_to_file filepath, str
      @@file_manip.prepend_to_file(File.expand_path(filepath), str)
    end

    def self.append_to_file filepath, str
      @@file_manip.append_to_file(File.expand_path(filepath), str)
    end
  end
end