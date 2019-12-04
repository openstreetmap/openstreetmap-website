require "stringio"

# The Potlatch module provides helper functions for potlatch and its communication with the server
module Potlatch
  # The AMF class is a set of helper functions for encoding and decoding AMF.
  class AMF
    # Return two-byte integer
    def self.getint(s)
      s.getbyte * 256 + s.getbyte
    end

    # Return four-byte long
    def self.getlong(s)
      ((s.getbyte * 256 + s.getbyte) * 256 + s.getbyte) * 256 + s.getbyte
    end

    # Return string with two-byte length
    def self.getstring(s)
      len = s.getbyte * 256 + s.getbyte
      str = s.read(len)
      str.force_encoding("UTF-8") if str.respond_to?("force_encoding")
      str
    end

    # Return eight-byte double-precision float
    def self.getdouble(s)
      a = s.read(8).unpack("G") # G big-endian, E little-endian
      a[0]
    end

    # Return numeric array
    def self.getarray(s)
      Array.new(getlong(s)) { getvalue(s) }
    end

    # Return object/hash
    def self.getobject(s)
      arr = {}
      while (key = getstring(s))
        break if key == ""

        arr[key] = getvalue(s)
      end
      s.getbyte # skip the 9 'end of object' value
      arr
    end

    # Parse and get value
    def self.getvalue(s)
      case s.getbyte
      when 0 then getdouble(s)                  # number
      when 1 then s.getbyte                     # boolean
      when 2 then getstring(s)                  # string
      when 3 then getobject(s)                  # object/hash
      when 5 then nil                           # null
      when 6 then nil                           # undefined
      when 8 then s.read(4) # mixedArray
                  getobject(s)                  #  |
      when 10 then getarray(s)                  # array
      end
    end

    # Envelope data into AMF writeable form
    def self.putdata(index, n)
      d = encodestring(index + "/onResult")
      d += encodestring("null")
      d += [-1].pack("N")
      d += encodevalue(n)
      d
    end

    # Pack variables as AMF
    def self.encodevalue(n)
      case n
      when Array
        a = 10.chr + encodelong(n.length)
        n.each do |b|
          a += encodevalue(b)
        end
        a
      when Hash
        a = 3.chr
        n.each do |k, v|
          a += encodestring(k.to_s) + encodevalue(v)
        end
        a + 0.chr + 0.chr + 9.chr
      when String
        2.chr + encodestring(n)
      when Numeric, GeoRecord::Coord
        0.chr + encodedouble(n)
      when NilClass
        5.chr
      when TrueClass
        0.chr + encodedouble(1)
      when FalseClass
        0.chr + encodedouble(0)
      else
        raise "Unexpected Ruby type for AMF conversion: #{n.class.name}"
      end
    end

    # Encode string with two-byte length
    def self.encodestring(n)
      n = n.dup.force_encoding("ASCII-8BIT") if n.respond_to?("force_encoding")
      a, b = n.size.divmod(256)
      a.chr + b.chr + n
    end

    # Encode number as eight-byte double precision float
    def self.encodedouble(n)
      [n.to_f].pack("G")
    end

    # Encode number as four-byte long
    def self.encodelong(n)
      [n].pack("N")
    end
  end

  # The Dispatcher class handles decoding a series of RPC calls
  # from the request, dispatching them, and encoding the response
  class Dispatcher
    def initialize(request, &_block)
      # Get stream for request data
      @request = StringIO.new(request + 0.chr)

      # Skip version indicator and client ID
      @request.read(2)

      # Skip headers
      AMF.getint(@request).times do     # Read number of headers and loop
        AMF.getstring(@request)         #  | skip name
        req.getbyte                     #  | skip boolean
        AMF.getvalue(@request)          #  | skip value
      end

      # Capture the dispatch routine
      @dispatch = Proc.new
    end

    def each(&_block)
      # Read number of message bodies
      bodies = AMF.getint(@request)

      # Output response header
      a, b = bodies.divmod(256)
      yield 0.chr + 0.chr + 0.chr + 0.chr + a.chr + b.chr

      # Process the bodies
      bodies.times do                     # Read each body
        name = AMF.getstring(@request)    #  | get message name
        index = AMF.getstring(@request)   #  | get index in response sequence
        AMF.getlong(@request)             #  | get total size in bytes
        args = AMF.getvalue(@request)     #  | get response (probably an array)

        result = @dispatch.call(name, *args)

        yield AMF.putdata(index, result)
      end
    end
  end

  # The Potlatch class is a helper for Potlatch
  class Potlatch
    # ----- getpresets
    #      in:   none
    #      does: reads tag preset menus, colours, and autocomplete config files
    #        out:  [0] presets, [1] presetmenus, [2] presetnames,
    #        [3] colours, [4] casing, [5] areas, [6] autotags
    #        (all hashes)
    def self.get_presets
      Rails.logger.info("  Message: getpresets")

      # Read preset menus
      presets = {}
      presetmenus = { "point" => [], "way" => [], "POI" => [] }
      presetnames = { "point" => {}, "way" => {}, "POI" => {} }
      presettype = ""
      presetcategory = ""
      #  StringIO.open(txt) do |file|
      File.open(Rails.root.join("config/potlatch/presets.txt")) do |file|
        file.each_line do |line|
          t = line.chomp
          if t =~ %r{(\w+)/(\w+)}
            presettype = Regexp.last_match(1)
            presetcategory = Regexp.last_match(2)
            presetmenus[presettype].push(presetcategory)
            presetnames[presettype][presetcategory] = ["(no preset)"]
          elsif t =~ /^([\w\s]+):\s?(.+)$/
            pre = Regexp.last_match(1)
            kv = Regexp.last_match(2)
            presetnames[presettype][presetcategory].push(pre)
            presets[pre] = {}
            kv.split(",").each do |a|
              presets[pre][Regexp.last_match(1)] = Regexp.last_match(2) if a =~ /^(.+)=(.*)$/
            end
          end
        end
      end

      # Read colours/styling
      colours = {}
      casing = {}
      areas = {}
      File.open(Rails.root.join("config/potlatch/colours.txt")) do |file|
        file.each_line do |line|
          next unless line.chomp =~ /(\w+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/

          tag = Regexp.last_match(1)
          colours[tag] = Regexp.last_match(2).hex if Regexp.last_match(2) != "-"
          casing[tag] = Regexp.last_match(3).hex if Regexp.last_match(3) != "-"
          areas[tag] = Regexp.last_match(4).hex if Regexp.last_match(4) != "-"
        end
      end

      # Read relations colours/styling
      relcolours = {}
      relalphas = {}
      relwidths = {}
      File.open(Rails.root.join("config/potlatch/relation_colours.txt")) do |file|
        file.each_line do |line|
          next unless line.chomp =~ /(\w+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/

          tag = Regexp.last_match(1)
          relcolours[tag] = Regexp.last_match(2).hex if Regexp.last_match(2) != "-"
          relalphas[tag] = Regexp.last_match(3).to_i if Regexp.last_match(3) != "-"
          relwidths[tag] = Regexp.last_match(4).to_i if Regexp.last_match(4) != "-"
        end
      end

      # Read POI presets
      icon_list = []
      icon_tags = {}
      File.open(Rails.root.join("config/potlatch/icon_presets.txt")) do |file|
        file.each_line do |line|
          (icon, tags) = line.chomp.split("\t")
          icon_list.push(icon)
          icon_tags[icon] = Hash[*tags.scan(/([^;=]+)=([^;=]+)/).flatten]
        end
      end
      icon_list.reverse!

      # Read auto-complete
      autotags = { "point" => {}, "way" => {}, "POI" => {} }
      File.open(Rails.root.join("config/potlatch/autocomplete.txt")) do |file|
        file.each_line do |line|
          next unless line.chomp =~ %r{^([\w:]+)/(\w+)\s+(.+)$}

          tag = Regexp.last_match(1)
          type = Regexp.last_match(2)
          values = Regexp.last_match(3)
          autotags[type][tag] = if values == "-"
                                  []
                                else
                                  values.split(",").sort.reverse
                                end
        end
      end

      [presets, presetmenus, presetnames, colours, casing, areas, autotags, relcolours, relalphas, relwidths, icon_list, {}, icon_tags]
    end
  end
end
