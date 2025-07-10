# frozen_string_literal: true

require 'json'

module FFMPEG
  module DASH
    # Provides class methods for HLS-related functionality.
    module HLSClassMethods
      private

      def quote(value)
        return if value.nil?

        JSON.generate(value.to_s)
      end

      def m3u8t(tag, attributes)
        if attributes.is_a?(Hash)
          "##{tag}:#{attributes.filter_map { |k, v| "#{k}=#{v}" unless v.nil? }.join(',')}"
        else
          "##{tag}:#{attributes.join(',')}"
        end
      end
    end
  end
end
