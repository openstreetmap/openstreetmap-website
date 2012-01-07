require 'stringio'

# The Potlatch module provides helper functions for potlatch and its communication with the server
module Potlatch

  # The AMF class is a set of helper functions for encoding and decoding AMF.
  class AMF
    
    # Return two-byte integer
    def self.getint(s) 
      s.getc*256+s.getc
    end

    # Return four-byte long
    def self.getlong(s) 
      ((s.getc*256+s.getc)*256+s.getc)*256+s.getc
    end

    # Return string with two-byte length 
    def self.getstring(s) 
      len=s.getc*256+s.getc
      s.read(len)
    end

    # Return eight-byte double-precision float 
    def self.getdouble(s) 
      a=s.read(8).unpack('G')			# G big-endian, E little-endian
      a[0]
    end

    # Return numeric array
    def self.getarray(s) 
      len=getlong(s)
      arr=[]
      for i in (0..len-1)
        arr[i]=getvalue(s)
      end
      arr
    end

    # Return object/hash 
    def self.getobject(s) 
      arr={}
      while (key=getstring(s))
        if (key=='') then break end
        arr[key]=getvalue(s)
      end
      s.getc		# skip the 9 'end of object' value
      arr
    end

    # Parse and get value
    def self.getvalue(s) 
      case s.getc
      when 0;	return getdouble(s)			# number
      when 1;	return s.getc				# boolean
      when 2;	return getstring(s)			# string
      when 3;	return getobject(s)			# object/hash
      when 5;	return nil					# null
      when 6;	return nil					# undefined
      when 8;	s.read(4)					# mixedArray
        return getobject(s)			#  |
      when 10;return getarray(s)			# array
      else;	return nil					# error
      end
    end

    # Envelope data into AMF writeable form
    def self.putdata(index,n) 
      d =encodestring(index+"/onResult")
      d+=encodestring("null")
      d+=[-1].pack("N")
      d+=encodevalue(n)
    end

    # Pack variables as AMF
    def self.encodevalue(n) 
      case n.class.to_s
      when 'Array'
        a=10.chr+encodelong(n.length)
        n.each do |b|
          a+=encodevalue(b)
        end
        a
      when 'Hash'
        a=3.chr
        n.each do |k,v|
          a+=encodestring(k.to_s)+encodevalue(v)
        end
        a+0.chr+0.chr+9.chr
      when 'String'
        2.chr+encodestring(n)
      when 'Bignum','Fixnum','Float'
        0.chr+encodedouble(n)
      when 'NilClass'
        5.chr
	  when 'TrueClass'
        0.chr+encodedouble(1)
	  when 'FalseClass'
        0.chr+encodedouble(0)
      else
        Rails.logger.error("Unexpected Ruby type for AMF conversion: "+n.class.to_s)
      end
    end

    # Encode string with two-byte length
    def self.encodestring(n) 
      a,b=n.size.divmod(256)
      a.chr+b.chr+n
    end

    # Encode number as eight-byte double precision float 
    def self.encodedouble(n) 
      [n].pack('G')
    end

    # Encode number as four-byte long
    def self.encodelong(n) 
      [n].pack('N')
    end

  end

  # The Dispatcher class handles decoding a series of RPC calls
  # from the request, dispatching them, and encoding the response
  class Dispatcher
    def initialize(request, &block)
      # Get stream for request data
      @request = StringIO.new(request + 0.chr)

      # Skip version indicator and client ID
      @request.read(2)

      # Skip headers
      AMF.getint(@request).times do     # Read number of headers and loop
        AMF.getstring(@request)         #  | skip name
        req.getc                        #  | skip boolean
        AMF.getvalue(@request)          #  | skip value
      end

      # Capture the dispatch routine
      @dispatch = Proc.new
    end

    def each(&block)
      # Read number of message bodies
      bodies = AMF.getint(@request)

      # Output response header
      a,b = bodies.divmod(256)
      yield 0.chr + 0.chr + 0.chr + 0.chr + a.chr + b.chr

      # Process the bodies
      bodies.times do                     # Read each body
        name = AMF.getstring(@request)    #  | get message name
        index = AMF.getstring(@request)   #  | get index in response sequence
        bytes = AMF.getlong(@request)     #  | get total size in bytes
        args = AMF.getvalue(@request)     #  | get response (probably an array)

        result = @dispatch.call(name, *args)

        yield AMF.putdata(index, result)
      end
    end
  end

  # The Potlatch class is a helper for Potlatch
  class Potlatch

    # ----- getpresets
    #		  in:   none
    #		  does: reads tag preset menus, colours, and autocomplete config files
    #	      out:  [0] presets, [1] presetmenus, [2] presetnames,
    #				[3] colours, [4] casing, [5] areas, [6] autotags
    #				(all hashes)
    def self.get_presets
      Rails.logger.info("  Message: getpresets")

      # Read preset menus
      presets={}
      presetmenus={}; presetmenus['point']=[]; presetmenus['way']=[]; presetmenus['POI']=[]
      presetnames={}; presetnames['point']={}; presetnames['way']={}; presetnames['POI']={}
      presettype=''
      presetcategory=''
      #	StringIO.open(txt) do |file|
      File.open("#{Rails.root}/config/potlatch/presets.txt") do |file|
        file.each_line {|line|
          t=line.chomp
          if (t=~/(\w+)\/(\w+)/) then
            presettype=$1
            presetcategory=$2
            presetmenus[presettype].push(presetcategory)
            presetnames[presettype][presetcategory]=["(no preset)"]
          elsif (t=~/^([\w\s]+):\s?(.+)$/) then
            pre=$1; kv=$2
            presetnames[presettype][presetcategory].push(pre)
            presets[pre]={}
            kv.split(',').each {|a|
              if (a=~/^(.+)=(.*)$/) then presets[pre][$1]=$2 end
            }
          end
        }
      end

      # Read colours/styling
      colours={}; casing={}; areas={}
      File.open("#{Rails.root}/config/potlatch/colours.txt") do |file|
        file.each_line {|line|
          t=line.chomp
          if (t=~/(\w+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/) then
            tag=$1
            if ($2!='-') then colours[tag]=$2.hex end
            if ($3!='-') then casing[tag]=$3.hex end
            if ($4!='-') then areas[tag]=$4.hex end
          end
        }
      end

      # Read relations colours/styling
      relcolours={}; relalphas={}; relwidths={}
      File.open("#{Rails.root}/config/potlatch/relation_colours.txt") do |file|
        file.each_line {|line|
          t=line.chomp
          if (t=~/(\w+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/) then
            tag=$1
            if ($2!='-') then relcolours[tag]=$2.hex end
            if ($3!='-') then relalphas[tag]=$3.to_i end
            if ($4!='-') then relwidths[tag]=$4.to_i end
          end
        }
      end

      # Read POI presets
      icon_list=[]; icon_tags={};
      File.open("#{Rails.root}/config/potlatch/icon_presets.txt") do |file|
        file.each_line {|line|
          (icon,tags)=line.chomp.split("\t")
          icon_list.push(icon)
          icon_tags[icon]=Hash[*tags.scan(/([^;=]+)=([^;=]+)/).flatten]
        }
      end
      icon_list.reverse!
      
      # Read auto-complete
      autotags={}; autotags['point']={}; autotags['way']={}; autotags['POI']={};
      File.open("#{Rails.root}/config/potlatch/autocomplete.txt") do |file|
        file.each_line {|line|
          t=line.chomp
          if (t=~/^([\w:]+)\/(\w+)\s+(.+)$/) then
            tag=$1; type=$2; values=$3
            if values=='-' then autotags[type][tag]=[]
            else autotags[type][tag]=values.split(',').sort.reverse end
          end
        }
      end

      [presets,presetmenus,presetnames,colours,casing,areas,autotags,relcolours,relalphas,relwidths,icon_list,{},icon_tags]
    end
  end

end

