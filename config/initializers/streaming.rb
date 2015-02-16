# Hack ActionController::DataStreaming to allow streaming from a file handle
module ActionController
  module DataStreaming
    alias_method :old_send_file, :send_file

    def send_file(file, options = {})
      if file.is_a?(File) || file.is_a?(Tempfile)
        headers["Content-Length"] ||= file.size.to_s

        options[:filename] ||= File.basename(file.path) unless options[:url_based_filename]
        send_file_headers! options

        self.status = options[:status] || 200
        self.content_type = options[:content_type] if options.key?(:content_type)
        self.response_body = file
      else
        headers["Content-Length"] ||= File.size(file).to_s

        old_send_file(file, options)
      end
    end
  end
end
