# frozen_string_literal: true

require_relative 'hls_class_methods'
require_relative 'representation'

module FFMPEG
  module DASH
    # Represents an Adaptation Set in a DASH manifest.
    class AdaptationSet
      include HLSClassMethods

      attr_reader :manifest

      def initialize(manifest, node)
        @manifest = manifest
        @node = node
      end

      # Returns the ID of the adaptation set.
      #
      # @return [Integer, nil] The ID of the adaptation set.
      def id
        @id ||= @node['id']&.to_i
      end

      # Returns the aspect ratio of the adaptation set.
      #
      # @return [String, nil] The pixel aspect ratio.
      def par
        @par ||= @node['par']
      end

      # Returns the language of the adaptation set.
      #
      # @return [String, nil] The language code (e.g., 'und', 'en', 'fr').
      def lang
        @lang ||= @node['lang']
      end

      # Returns the content type of the adaptation set.
      #
      # @return [String, nil] The content type.
      def content_type
        @content_type ||= @node['contentType']
      end

      # Returns the max width of the adaptation set.
      #
      # @return [Integer, nil] The maximum width in pixels.
      def max_width
        @max_width ||= @node['maxWidth']&.to_i
      end

      # Returns the max height of the adaptation set.
      #
      # @return [Integer, nil] The maximum height in pixels.
      def max_height
        @max_height ||= @node['maxHeight']&.to_i
      end

      # Returns the frame rate of the adaptation set.
      #
      # @return [Rational, nil] The frame rate as a Rational number.
      def frame_rate
        @frame_rate ||= @node['frameRate']&.to_r
      end

      # Returns the representations in the adaptation set.
      #
      # @return [Array<Representation>] An array of Representation objects.
      def representations
        @representations ||=
          @node
          .xpath('./xmlns:Representation')
          .map { Representation.new(self, _1) }
      end

      # Sets the base URL for all representations in the adaptation set.
      #
      # @param value [String] The base URL to set.
      # @return [void]
      def base_url=(value)
        representations.each { _1.base_url = value }
      end

      # Sets the segment query for all representations in the adaptation set.
      #
      # @param value [String] The segment query to set.
      # @return [void]
      def segment_query=(value)
        representations.each { _1.segment_query = value }
      end

      # Returns the representation as a string in M3U8 (HLS playlist) media track format.
      # NOTE: Currently we only support audio and video representations.
      #
      # See https://datatracker.ietf.org/doc/html/rfc8216
      #
      # @param default [Boolean] Whether to mark media track as default or not.
      # @param autoselect [Boolean] Whether to mark media track as automatically selected or not.
      # @param group_id [String, nil] The group ID for media track.
      # @return [String, nil] The M3U8 EXT-X-MEDIA formatted string for the representation.
      def to_m3u8mt(group_id: content_type, default: true, autoselect: true)
        return unless %w[audio video].include?(content_type)
        return unless representations.any?

        m3u8t(
          'EXT-X-MEDIA',
          'TYPE' => content_type.upcase,
          'GROUP-ID' => group_id,
          'NAME' => quote(lang || 'und'),
          'LANGUAGE' => quote(lang || 'und'),
          'DEFAULT' => default ? 'YES' : 'NO',
          'AUTOSELECT' => autoselect ? 'YES' : 'NO',
          'URI' => quote("stream#{representations.first.id}.m3u8")
        )
      end

      private

      def respond_to_missing?(name, include_private = false)
        @node.respond_to?(name, include_private) || super
      end

      def method_missing(name, *args, &)
        @node.send(name, *args, &)
      end
    end
  end
end
