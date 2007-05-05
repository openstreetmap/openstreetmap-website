class AmfController < ApplicationController
  require 'stringio'

  # Still to do:
  # - all db interaction
  # - user authentication
  # - (also pass lat/lon through from view tab to edit tab)

# to log:
# RAILS_DEFAULT_LOGGER.error("Args: #{args[0]}, #{args[1]}, #{args[2]}, #{args[3]}")


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
		waylist=WaySegment.find_by_sql("SELECT DISTINCT current_way_segments.id AS wayid"+
			 "  FROM current_way_segments,current_segments,current_nodes "+
			 " WHERE segment_id=current_segments.id "+
			 "   AND node_a=current_nodes.id "+
			 "   AND (latitude  BETWEEN "+(args[1].to_f-0.01).to_s+" AND "+(args[3].to_f+0.01).to_s+") "+
			 "   AND (longitude BETWEEN "+(args[0].to_f-0.01).to_s+" AND "+(args[2].to_f+0.01).to_s+")")
		ways=[]
		waylist.each {|a|
			ways<<a.wayid.to_i
RAILS_DEFAULT_LOGGER.error("Found #{a.wayid.to_i}")
		}
		ways
	end
	
	def getway(args)
		objname,wayid,$baselong,$basey,$masterscale=args
		wayid=wayid.to_i
		points=[]
		lastid=-1
		xmin=999999; xmax=-999999
		ymin=999999; ymax=-999999

RAILS_DEFAULT_LOGGER.error("Looking for way #{wayid}")
		nodelist=ActiveRecord::Base.connection.select_all "SELECT n1.latitude AS lat1,n1.longitude AS long1,n1.id AS id1,n1.tags as tags1, "+
			"		  n2.latitude AS lat2,n2.longitude AS long2,n2.id AS id2,n2.tags as tags2,segment_id "+
			"    FROM current_way_segments,current_segments,current_nodes AS n1,current_nodes AS n2 "+
			"   WHERE current_way_segments.id=#{wayid} "+
			"     AND segment_id=current_segments.id "+
			"     AND n1.id=node_a and n2.id=node_b "+
			"   ORDER BY sequence_id"
		nodelist.each {|row|
			xs1=long2coord(row['long1'].to_f); ys1=lat2coord(row['lat1'].to_f)
			xs2=long2coord(row['long2'].to_f); ys2=lat2coord(row['lat2'].to_f)
			if (row['id1'].to_i!=lastid)
				points<<[xs1,ys1,row['id1'].to_i,0,tag2array(row['tags1']),0]
			end
			lastid=row['id2'].to_i
			points<<[xs2,ys2,row['id2'].to_i,1,tag2array(row['tags2']),row['segment_id'].to_i]
			xmin=[xmin,row['long1'].to_f,row['long2'].to_f].min
			xmax=[xmax,row['long1'].to_f,row['long2'].to_f].max
			ymin=[ymin,row['lat1'].to_f,row['lat2'].to_f].min
			ymax=[ymax,row['lat1'].to_f,row['lat2'].to_f].max
		}
			
		attributes={}
		attrlist=ActiveRecord::Base.connection.select_all "SELECT k,v FROM current_way_tags WHERE id=#{wayid}"
		attrlist.each {|a| attributes[a['k']]=a['v'] }

RAILS_DEFAULT_LOGGER.error("Way #{wayid} #{xmin},#{xmax},#{ymin},#{ymax}")
		[objname,points,attributes,xmin,xmax,ymin,ymax]
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

	def tag2array(a)
		tags={}
		a.gsub('\;','#%').split(';').each do |b|
			b.gsub!('#%',';')
			k,v=b.split('=')
			tags[k]=v
		end
		tags
	end
	

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
			else
				RAILS_DEFAULT_LOGGER.error("Unexpected Ruby type for AMF conversion: "+n.class.to_s)
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
