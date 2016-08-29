require 'CFPropertyList'

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

    def self.kill_zombie_children

      # process id of current thread
      parent_pid = Process.pid

      # get a list of processes and children
      process_output = `ps -eo pid,ppid,args | grep #{parent_pid} | grep -iv grep`

      # break out column output into pid, parent_id, command
      matches = process_output.scan /^\s*(\d+)\s*(\d+)\s*(.*)$/
      return nil if matches.nil? || matches.empty?

      # check for children
      got_children = false
      matches.each do |match|
        next if match.size != 3
        next if got_children == true
        got_children = true if match[1].to_i == parent_pid
      end
      return nil unless got_children

      # fork process
      pid = Process.fork

      if pid.nil?
        # execute "self"
        exec $0
      else
        # detach child process, kill self
        Process.detach pid
        Process.kill 9, Process.pid
      end

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

    def self.parse_plist str
      CFPropertyList.native_types(CFPropertyList::List.new(:data => str).value)
    end

    def self.read_plist filename
      CFPropertyList.native_types(CFPropertyList::List.new(:file => filename).value)
    end

    def self.write_plist filename, data
      plist = CFPropertyList::List.new
      plist.value = CFPropertyList.guess(data)
      plist.save(filename, CFPropertyList::List::FORMAT_XML)
    end
  end
end
