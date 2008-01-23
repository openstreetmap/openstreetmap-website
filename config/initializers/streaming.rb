# Hack ActionController::Streaming to allow streaming from a file handle
module ActionController
  module Streaming
    alias_method :old_send_file, :send_file

    def send_file(file, options = {})
      if file.is_a? File or file.is_a? Tempfile
        options[:length] ||= file.stat.size
        options[:filename] ||= File.basename(file.path) unless options[:url_based_filename]
        send_file_headers! options

        @performed_render = false

        if options[:stream]
          render :status => options[:status], :text => Proc.new { |response, output|
            logger.info "Streaming file #{file.path}" unless logger.nil?
            len = options[:buffer_size] || 4096
            while buf = file.read(len)
              output.write(buf)
            end
          }
        else
          logger.info "Sending file #{file.path}" unless logger.nil?
          render :status => options[:status], :text => file.read
        end
      else
        old_send_file(file, options)
      end
    end
  end
end
