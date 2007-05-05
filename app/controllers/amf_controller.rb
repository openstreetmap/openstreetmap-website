class AmfController < ApplicationController
  require 'stringio'

  # Still to do:
  # - all db interaction
  # - user authentication
  # - (also pass lat/lon through from view tab to edit tab)

  # ====================================================================
  # Main AMF handler
  
  # ---- talk	process AMF request

  def talk
	req=StringIO.new(request.raw_post)	# Get POST data as request
	req.read(2)							# Skip version indicator and client ID
	results={}							# Results of each body

	# -------------
	# Parse request

	headers=getint(req)					# Read number of headers
	for i in (1..headers)				# Read each header
		name=getstring(req)				#  |
		req.getc						#  | skip boolean
		value=getvalue(req)				#  |
		header["name"]=value			#  |
	end

	bodies=getint(req)					# Read number of bodies
	for i in (1..bodies)				# Read each body
		message=getstring(req)			#  | get message name
		index=getstring(req)			#  | get index in response sequence
		bytes=getlong(req)				#  | get total size in bytes
		args=getvalue(req)				#  | get response (probably an array)
	
		case message
			when 'getpresets';	results[index]=putdata(index,getpresets)
			when 'whichways';	results[index]=putdata(index,whichways(args))
			when 'getway';		results[index]=putdata(index,getway(args))
			when 'putway';		results[index]=putdata(index,putway(args))
			when 'deleteway';	results[index]=putdata(index,deleteway(args))
		end
	end

	# ------------------
	# Write out response

	response.headers["Content-Type"]="application/x-amf"
	a,b=results.length.divmod(256)
	ans=0.chr+0.chr+0.chr+0.chr+a.chr+b.chr
	results.each do |k,v|
		ans+=v
	end
	render :text=>ans

  end


	# ====================================================================
	# Remote calls

	def getpresets
		presets={}
		presetmenus={}; presetmenus['point']=[]; presetmenus['way']=[]
		presetnames={}; presetnames['point']={}; presetnames['way']={}
		presettype=''
		presetcategory=''
		
		File.open("config/potlatch/presets.txt") do |file|
			file.each_line {|line|
				t=line.chomp
				if (t=~/(\w+)\/(\w+)/) then
					presettype=$1
					presetcategory=$2
					presetmenus[presettype].push(presetcategory)
					presetnames[presettype][presetcategory]=["(no preset)"]
				elsif (t=~/^(.+):\s?(.+)$/) then
					pre=$1; kv=$2
					presetnames[presettype][presetcategory].push(pre)
					presets[pre]={}
					kv.split(',').each {|a|
						if (a=~/^(.+)=(.*)$/) then presets[pre][$1]=$2 end
					}
				end
			}
		end
		[presets,presetmenus,presetnames]
	end

	def whichways(args)
		# to do
	end
	
	def getway(args)
		# to do
	end
	
	def putway(args)
		# to do
	end
	
	def deleteway(args)
		# to do
	end
	
	# need support functions here too:
	#	database support functions (readwayquery, createuniquesegments)
	#	tag2array, array2tag
	#	getuserid

	# ====================================================================
	# AMF read subroutines
	
	# -----	getint		return two-byte integer
	# -----	getlong		return four-byte long
	# -----	getstring	return string with two-byte length
	# ----- getdouble	return eight-byte double-precision float
	# ----- getobject	return object/hash
	# ----- getarray	return numeric array
	
	def getint(s)
		s.getc*256+s.getc
	end
	
	def getlong(s)
		((s.getc*256+s.getc)*256+s.getc)*256+s.getc
	end
	
	def getstring(s)
		len=s.getc*256+s.getc
		s.read(len)
	end
	
	def getdouble(s)
		a=s.read(8).unpack('G')			# G big-endian, E little-endian
		a[0]
	end
	
	def getarray(s)
		len=getlong(s)
		arr=[]
		for i in (0..len-1)
			arr[i]=getvalue(s)
		end
		arr
	end
	
	def getobject(s)
		arr={}
		while (key=getstring(s))
			if (key=='') then break end
			arr[key]=getvalue(s)
		end
		s.getc		# skip the 9 'end of object' value
		arr
	end
	
	# -----	getvalue	parse and get value
	
	def getvalue(s)
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

	# ====================================================================
	# AMF write subroutines
	
	# -----	putdata		envelope data into AMF writeable form
	# -----	encodevalue	pack variables as AMF
	
	def putdata(index,n)
		d =encodestring(index+"/onResult")
		d+=encodestring("null")
		d+=[-1].pack("N")
		d+=encodevalue(n)
	end
	
	def encodevalue(n)
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
					a+=encodestring(k)+encodevalue(v)
				end
				a+0.chr+0.chr+9.chr
			when 'String'
				2.chr+encodestring(n)
			when 'Bignum','Fixnum','Float'
				0.chr+encodedouble(n)
			when 'NilClass'
				5.chr
		end
	end
	
	# -----	encodestring	encode string with two-byte length
	# -----	encodedouble	encode number as eight-byte double precision float
	# -----	encodelong		encode number as four-byte long
	
	def encodestring(n)
		a,b=n.size.divmod(256)
		a.chr+b.chr+n
	end
	
	def encodedouble(n)
		[n].pack('G')
	end
	
	def encodelong(n)
		[n].pack('N')
	end
	
	# ====================================================================
	# Co-ordinate conversion
	
	def lat2coord(a)
		-(lat2y(a)-$basey)*$masterscale+250
	end
	
	def long2coord(a)
		(a-$baselong)*$masterscale+350
	end
	
	def lat2y(a)
		180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
	end
	
	def coord2lat(a)
		y2lat((a-250)/-$masterscale+$basey)
	end
	
	def coord2long(a)
		(a-350)/$masterscale+$baselong
	end
	
	def y2lat(a)
		180/Math::PI * (2*Math.atan(Math.exp(a*Math::PI/180))-Math::PI/2)
	end


end
