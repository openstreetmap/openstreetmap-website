class SwfController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_api_readable

  # to log:
  # RAILS_DEFAULT_LOGGER.error("Args: #{args[0]}, #{args[1]}, #{args[2]}, #{args[3]}")
  # $log.puts Time.new.to_s+','+Time.new.usec.to_s+": started GPS script"
  # http://localhost:3000/api/0.4/swf/trackpoints?xmin=-2.32402605810577&xmax=-2.18386309423859&ymin=52.1546608755772&ymax=52.2272777906895&baselong=-2.25325793066437&basey=61.3948537948532&masterscale=5825.4222222222

  # ====================================================================
  # Public methods

  # ---- trackpoints	compile SWF of trackpoints

  def trackpoints
    # -	Initialise

    baselong = params['baselong'].to_f
    basey = params['basey'].to_f
    masterscale = params['masterscale'].to_f

    bbox = BoundingBox.new(params['xmin'], params['ymin'],
                           params['xmax'], params['ymax'])
    start = params['start'].to_i

    # -	Begin movie

    bounds_left = 0
    bounds_right = 320 * 20
    bounds_bottom = 0
    bounds_top = 240 * 20

    m = ''
    m += swfRecord(9, 255.chr + 155.chr + 155.chr)			# Background
    absx = 0
    absy = 0
    xl = yb = 9999999
    xr = yt = -9999999

    # -	Send SQL for GPS tracks

    b = ''
    lasttime = 0
    lasttrack = lastfile = '-1'

    if params['token']
      user = User.authenticate(:token => params[:token])
      sql = "SELECT gps_points.latitude*0.0000001 AS lat,gps_points.longitude*0.0000001 AS lon,gpx_files.id AS fileid," + 		       "      EXTRACT(EPOCH FROM gps_points.timestamp) AS ts, gps_points.trackid AS trackid " + 			   " FROM gpx_files,gps_points " + 			   "WHERE gpx_files.id=gpx_id " + 			   "  AND gpx_files.user_id=#{user.id} " + 			   "  AND " + OSM.sql_for_area(bbox, "gps_points.") + 			   "  AND (gps_points.timestamp IS NOT NULL) " + 			   "ORDER BY fileid DESC,ts " + 			   "LIMIT 10000 OFFSET #{start}"
    else
      sql = "SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lon,gpx_id AS fileid," + 			     "      EXTRACT(EPOCH FROM timestamp) AS ts, gps_points.trackid AS trackid " + 				 " FROM gps_points " + 				 "WHERE " + OSM.sql_for_area(bbox, "gps_points.") + 				 "  AND (gps_points.timestamp IS NOT NULL) " + 				 "ORDER BY fileid DESC,ts " + 				 "LIMIT 10000 OFFSET #{start}"
    end
    gpslist = ActiveRecord::Base.connection.select_all sql

    # - Draw GPS trace lines

    r = startShape
    gpslist.each do |row|
      xs = (long2coord(row['lon'].to_f, baselong, masterscale) * 20).floor
      ys = (lat2coord(row['lat'].to_f, basey, masterscale) * 20).floor
      xl = [xs, xl].min; xr = [xs, xr].max
      yb = [ys, yb].min; yt = [ys, yt].max
      if row['ts'].to_i - lasttime > 180 || row['fileid'] != lastfile || row['trackid'] != lasttrack # or row['ts'].to_i==lasttime
        b += startAndMove(xs, ys, '01')
        absx = xs.floor; absy = ys.floor
      end
      b += drawTo(absx, absy, xs, ys)
      absx = xs.floor; absy = ys.floor
      lasttime = row['ts'].to_i
      lastfile = row['fileid']
      lasttrack = row['trackid']
      while b.length > 80
        r += [b.slice!(0...80)].pack("B*")
      end
    end

    #   (Unwayed segments removed)

    # - Write shape

    b += endShape
    r += [b].pack("B*")
    m += swfRecord(2, packUI16(1) + packRect(xl, xr, yb, yt) + r)
    m += swfRecord(4, packUI16(1) + packUI16(1))

    # -	Create Flash header and write to browser

    m += swfRecord(1, '')									# Show frame
    m += swfRecord(0, '')									# End

    m = packRect(bounds_left, bounds_right, bounds_bottom, bounds_top) + 0.chr + 12.chr + packUI16(1) + m
    m = 'FWS' + 6.chr + packUI32(m.length + 8) + m

    render :text => m, :content_type => "application/x-shockwave-flash"
  end

  private

  # =======================================================================
  # SWF functions

  # -----------------------------------------------------------------------
  # Line-drawing

  def startShape
    s = 0.chr						# No fill styles
    s += 2.chr						# Two line styles
    s += packUI16(0) + 0.chr + 255.chr + 255.chr	# Width 5, RGB #00FFFF
    s += packUI16(0) + 255.chr + 0.chr + 255.chr	# Width 5, RGB #FF00FF
    s += 34.chr										# 2 fill, 2 line index bits
    s
  end

  def endShape
    '000000'
  end

  def startAndMove(x, y, col)
    d = '001001'					# Line style change, moveTo
    l = [lengthSB(x), lengthSB(y)].max
    d += sprintf("%05b%0#{l}b%0#{l}b", l, x, y)
    d += col						# Select line style
    d
  end

  def drawTo(absx, absy, x, y)
    dx = x - absx
    dy = y - absy

    # Split the line up if there's anything>16383, because
    # that would overflow the 4 bits allowed for length
    mstep = [dx.abs / 16383, dy.abs / 16383, 1].max.ceil
    xstep = dx / mstep
    ystep = dy / mstep
    d = ''
    1.upto(mstep).each do
      d += drawSection(x, y, x + xstep, y + ystep)
      x += xstep
      y += ystep
    end
    d
  end

  def drawSection(x1, y1, x2, y2)
    d = '11'											# TypeFlag, EdgeFlag
    dx = x2 - x1
    dy = y2 - y1
    l = [lengthSB(dx), lengthSB(dy)].max
    d += sprintf("%04b", l - 2)
    d += '1'											# GeneralLine
    d += sprintf("%0#{l}b%0#{l}b", dx, dy)
    d
  end

  # -----------------------------------------------------------------------
  # Specific data types

  # SWF data block type

  def swfRecord(id, r)
    if r.length > 62
      # Long header: tag id, 0x3F, length
      return packUI16((id << 6) + 0x3F) + packUI32(r.length) + r
    else
      # Short header: tag id, length
      return packUI16((id << 6) + r.length) + r
    end
  end

  # SWF RECT type

  def packRect(a, b, c, d)
    l = [lengthSB(a),
         lengthSB(b),
         lengthSB(c),
         lengthSB(d)].max
    # create binary string (00111001 etc.) - 5-byte length, then bbox
    n = sprintf("%05b%0#{l}b%0#{l}b%0#{l}b%0#{l}b", l, a, b, c, d)
    # pack into byte string
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
    Math.frexp(n + (n == 0 ? 1 : 0))[1] + 1
  end

  # ====================================================================
  # Co-ordinate conversion
  # (this is duplicated from amf_controller, should probably share)

  def lat2coord(a, basey, masterscale)
    -(lat2y(a) - basey) * masterscale
  end

  def long2coord(a, baselong, masterscale)
    (a - baselong) * masterscale
  end

  def lat2y(a)
    180 / Math::PI * Math.log(Math.tan(Math::PI / 4 + a * (Math::PI / 180) / 2))
  end

  def sqlescape(a)
    a.gsub("'", "''").gsub(92.chr, 92.chr + 92.chr)
  end
end
