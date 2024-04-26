# frozen_string_literal: true

require 'net/http'
require 'uri'

module FFMPEG
  # Utility methods
  class Utils
    def self.force_iso8859(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end

    def self.fetch_http_head(url, max_redirect_attempts = FFMPEG.max_http_redirect_attempts)
      uri = URI(url)
      return unless uri.path

      conn = Net::HTTP.new(uri.host, uri.port)
      conn.use_ssl = uri.port == 443
      response = conn.request_head(uri.request_uri)

      case response
      when Net::HTTPRedirection
        raise FFMPEG::HTTPTooManyRedirects if max_redirect_attempts.zero?

        redirect_uri = uri + URI(response.header['Location'])

        fetch_http_head(redirect_uri, max_redirect_attempts - 1)
      else
        response
      end
    rescue SocketError, Errno::ECONNREFUSED
      nil
    end
  end
end
