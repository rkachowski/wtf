module Wtf
  module Util
    def self.camel_to_spaced str
      cpy = str.clone

      match_offsets = cpy.to_enum(:scan, /[a-z][A-Z]/).map {Regexp.last_match.begin(0)}
      match_offsets.each_with_index { |o,i| cpy.insert(o+i+1," ") }
      cpy
    end
  end
end