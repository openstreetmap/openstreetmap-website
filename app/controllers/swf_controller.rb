class SwfController < ApplicationController
	session :off
	before_filter :check_availability

# to log:
# RAILS_DEFAULT_LOGGER.error("Args: #{args[0]}, #{args[1]}, #{args[2]}, #{args[3]}")
# $log.puts Time.new.to_s+','+Time.new.usec.to_s+": started GPS script"
# http://localhost:3000/api/0.4/swf/trackpoints?xmin=-2.32402605810577&xmax=-2.18386309423859&ymin=52.1546608755772&ymax=52.2272777906895&baselong=-2.25325793066437&basey=61.3948537948532&masterscale=5825.4222222222

	# ====================================================================
	# Public methods
	
	# ---- trackpoints	compile SWF of trackpoints

	def trackpoints	
	
		# -	Initialise
	
		baselong	=params['baselong'].to_f
		basey		=params['basey'].to_f
		masterscale	=params['masterscale'].to_f
	
		xmin=params['xmin'].to_f; xminr=xmin/0.000001
		xmax=params['xmax'].to_f; xmaxr=xmax/0.000001
		ymin=params['ymin'].to_f; yminr=ymin/0.000001
		ymax=params['ymax'].to_f; ymaxr=ymax/0.000001
	
		# -	Begin movie
	
		bounds_left  =0
		bounds_right =320*20
		bounds_bottom=0
		bounds_top   =240*20

		m =''
		m+=swfRecord(9,255.chr + 155.chr + 155.chr)			#ÊBackground
		absx=0
		absy=0
		xl=yb= 9999999
		xr=yt=-9999999
	
		# -	Send SQL for GPS tracks
	
		b=''
		lasttime=0
		lastfile='-1'
	
		if params['token']
                        user=User.authenticate(:token => params[:token])
			sql="SELECT gps_points.latitude*0.000001 AS lat,gps_points.longitude*0.000001 AS lon,gpx_files.id AS fileid,UNIX_TIMESTAMP(gps_points.timestamp) AS ts "+
				 " FROM gpx_files,gps_points "+
				 "WHERE gpx_files.id=gpx_id "+
				 "  AND gpx_files.user_id=#{user.id} "+
				 "  AND (gps_points.longitude BETWEEN #{xminr} AND #{xmaxr}) "+
				 "  AND (gps_points.latitude BETWEEN #{yminr} AND #{ymaxr}) "+
				 "  AND (gps_points.timestamp IS NOT NULL) "+
				 "ORDER BY fileid DESC,ts "+
				 "LIMIT 10000"
		else
			sql="SELECT latitude*0.000001 AS lat,longitude*0.000001 AS lon,gpx_id AS fileid,UNIX_TIMESTAMP(timestamp) AS ts "+
				 " FROM gps_points "+
				 "WHERE (longitude BETWEEN #{xminr} AND #{xmaxr}) "+
				 "  AND (latitude  BETWEEN #{yminr} AND #{ymaxr}) "+
				 "  AND (gps_points.timestamp IS NOT NULL) "+
				 "ORDER BY fileid DESC,ts "+
				 "LIMIT 10000"
		end
		gpslist=ActiveRecord::Base.connection.select_all sql
	
		# - Draw GPS trace lines
	
		r=startShape()
		gpslist.each do |row|
			xs=(long2coord(row['lon'].to_f,baselong,masterscale)*20).floor
			ys=(lat2coord(row['lat'].to_f ,basey   ,masterscale)*20).floor
			xl=[xs,xl].min; xr=[xs,xr].max
			yb=[ys,yb].min; yt=[ys,yt].max
			if (row['ts'].to_i-lasttime<180 and row['fileid']==lastfile)
				b+=drawTo(absx,absy,xs,ys)
			else
				b+=startAndMove(xs,ys,'01')
			end
			absx=xs.floor; absy=ys.floor
			lasttime=row['ts'].to_i
			lastfile=row['fileid']
			while b.length>80 do
				r+=[b.slice!(0...80)].pack("B*")
			end
		end
		
		# - Draw unwayed segments
		
		if params['unwayed']=='true'
			sql="SELECT cn1.latitude AS lat1,cn1.longitude AS lon1,"+
				"		cn2.latitude AS lat2,cn2.longitude AS lon2 "+
				"  FROM current_segments "+
				"       LEFT OUTER JOIN current_way_nodes"+
				"       ON segment_id=current_segments.id,"+
				"       current_nodes AS cn1,current_nodes AS cn2"+
				" WHERE (cn1.longitude BETWEEN #{xmin} AND #{xmax})"+
				"   AND (cn1.latitude  BETWEEN #{ymin} AND #{ymax})"+
				"   AND segment_id IS NULL"+
				"   AND current_segments.visible=1"+
				"   AND cn1.id=node_a AND cn1.visible=1"+
				"   AND cn2.id=node_b AND cn2.visible=1"
			seglist=ActiveRecord::Base.connection.select_all sql
			
			seglist.each do |row|
				xs1=(long2coord(row['lon1'].to_f,baselong,masterscale)*20).floor; ys1=(lat2coord(row['lat1'].to_f,basey,masterscale)*20).floor
				xs2=(long2coord(row['lon2'].to_f,baselong,masterscale)*20).floor; ys2=(lat2coord(row['lat2'].to_f,basey,masterscale)*20).floor
				if (xs1==absx and ys1==absy)
					b+=drawTo(absx,absy,xs2,ys2)
					absx=xs2; absy=ys2
				elsif (xs2==absx and ys2==absy)
					b+=drawTo(absx,absy,xs1,ys1)
					absx=xs1; absy=ys1
				else
					b+=startAndMove(xs1,ys1,'10')
					b+=drawTo(xs1,ys1,xs2,ys2)
					absx=xs2; absy=ys2
				end
				while b.length>80 do
					r+=[b.slice!(0...80)].pack("B*")
				end
			end
		end
	
		# - Write shape
	
		b+=endShape()
		r+=[b].pack("B*")
		m+=swfRecord(2,packUI16(1) + packRect(xl,xr,yb,yt) + r)
		m+=swfRecord(4,packUI16(1) + packUI16(1))
		
		# -	Create Flash header and write to browser
	
		m+=swfRecord(1,'')									# Show frame
		m+=swfRecord(0,'')									# End
		
		m=packRect(bounds_left,bounds_right,bounds_bottom,bounds_top) + 0.chr + 12.chr + packUI16(1) + m
		m='FWS' + 6.chr + packUI32(m.length+8) + m
	
		render :text => m, :content_type => "application/x-shockwave-flash"
	end

	private

	# =======================================================================
	# SWF functions
	
	# -----------------------------------------------------------------------
	# Line-drawing

	def startShape
		s =0.chr										# No fill styles
		s+=2.chr										# Two line styles
		s+=packUI16(5) + 0.chr + 255.chr + 255.chr		# Width 5, RGB #00FFFF
		s+=packUI16(5) + 255.chr + 0.chr + 255.chr		# Width 5, RGB #FF00FF
		s+=34.chr										# 2 fill, 2 line index bits
		s
	end
	
	def endShape
		'000000'
	end
	
	def startAndMove(x,y,col)
		d='001001'										# Line style change, moveTo
		l =[lengthSB(x),lengthSB(y)].max
		d+=sprintf("%05b%0#{l}b%0#{l}b",l,x,y)
		d+=col											# Select line style
	end
	
	def drawTo(absx,absy,x,y)
		d='11'											# TypeFlag, EdgeFlag
		dx=x-absx
		dy=y-absy
		
		l =[lengthSB(dx),lengthSB(dy)].max
		d+=sprintf("%04b",l-2)
		d+='1'											# GeneralLine
		d+=sprintf("%0#{l}b%0#{l}b",dx,dy)
	end

	# -----------------------------------------------------------------------
	# Specific data types

	def swfRecord(id,r)
		if r.length>62
			return packUI16((id<<6)+0x3F) + packUI32(r.length) + r
		else
			return packUI16((id<<6)+r.length) + r
		end
	end

	def packRect(a,b,c,d)
		l=[lengthSB(a),
		   lengthSB(b),
		   lengthSB(c),
		   lengthSB(d)].max
		n=sprintf("%05b%0#{l}b%0#{l}b%0#{l}b%0#{l}b",l,a,b,c,d)
		[n].pack("B*")
	end

	# -----------------------------------------------------------------------
	# Generic pack functions
	
	def packUI16(n)
		[n.floor].pack("v")
	end
	
	def packUI32(n)
		[n.floor].pack("V")
	end
	
	# Find number of bits required to store arbitrary-length binary
	
	def lengthSB(n)
		Math.frexp(n+ (n==0?1:0) )[1]+1
	end
	
	# ====================================================================
	# Co-ordinate conversion
	# (this is duplicated from amf_controller, should probably share)
	
	def lat2coord(a,basey,masterscale)
		-(lat2y(a)-basey)*masterscale+250
	end
	
	def long2coord(a,baselong,masterscale)
		(a-baselong)*masterscale+350
	end
	
	def lat2y(a)
		180/Math::PI * Math.log(Math.tan(Math::PI/4+a*(Math::PI/180)/2))
	end

	def sqlescape(a)
		a.gsub("'","''").gsub(92.chr,92.chr+92.chr)
	end

end
