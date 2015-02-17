# OutputCompression
# Rails output compression filters
#
# Adds two classmethods to ActionController that can be used as after-filters:
# strip_whitespace and compress_output.
# If you use page-caching, you MUST specify the compress_output filter AFTER
# caches_page, otherwise the compressed data will be cached instead of the HTML
#
# class MyController < ApplicationController
#  after_filter :strip_whitespace
#  caches_page :index
#  after_filter :compress_output
# end

begin
  require 'zlib'
  require 'stringio'
  GZIP_SUPPORTED = true
rescue
  GZIP_SUPPORTED = false
end

module CompressionSystem
  def compress_output
    return unless accepts_gzip?
    output = StringIO.new
    def output.close
      # Zlib does a close. Bad Zlib...
      rewind
    end
    gz = Zlib::GzipWriter.new(output)
    gz.write(response.body)
    gz.close
    if output.length < response.body.length
      @old_response_body = response.body
      response.body = output.string
      response.headers['Content-encoding'] = @compression_encoding
    end
  end

  def accepts_gzip?
    return false unless GZIP_SUPPORTED
    accepts = request.env['HTTP_ACCEPT_ENCODING']
    return false unless accepts && accepts =~ /(x-gzip|gzip)/
    @compression_encoding = $1
    true
  end

  def strip_whitespace
    response.body.gsub!(/()|(.*?<\/script>)|()|()|\s+/m) do |m|
      if m =~ /^()(.*?)<\/script>$/m
        $1 + $2.strip.gsub(/\s+/, ' ').gsub('', "\n-->") + ''
      elsif m =~ /^$/m
        ''
      elsif m =~ /^<(textarea|pre)/
        m
      else ' '
      end
    end
    response.body.gsub! /\s+\s+/, '>'
  end
end

module ActionController
  class Base
    include CompressionSystem
  end
end
