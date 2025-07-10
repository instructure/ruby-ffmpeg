# frozen_string_literal: true

require 'nokogiri'

require_relative 'adaptation_set'

module FFMPEG
  module DASH
    # Represents a DASH manifest document.
    class Manifest
      class << self
        # Parses a DASH manifest document and returns a Manifest object.
        #
        # @param document [String] The XML document as a string.
        # @return [Manifest] A new Manifest object containing the parsed document.
        def parse(document)
          new(Nokogiri::XML(document, &:noblanks))
        end
      end

      def initialize(document)
        @document = document
        @mpd = @document.at_xpath('/xmlns:MPD')
      end

      # Returns the type of the MPD (e.g., 'static', 'dynamic').
      #
      # @return [String, nil] The type of the MPD.
      def type
        @type ||= @mpd&.[]('type')
      end

      # Returns true if the MPD is a VOD (Video on Demand) manifest.
      #
      # @return [Boolean] True if the MPD is a VOD manifest, false otherwise.
      def vod?
        type != 'dynamic'
      end

      # Returns the adaptation sets in the MPD.
      #
      # @return [Array<AdaptationSet>] An array of AdaptationSet objects.
      def adaptation_sets
        @adaptation_sets ||=
          @mpd
          &.xpath('./xmlns:Period[1]/xmlns:AdaptationSet')
          &.map { AdaptationSet.new(self, _1) }
          .then { _1 || [] }
      end

      # Sets the base URL for all adaptation sets.
      #
      # @param value [String] The base URL to set.
      # @return [void]
      def base_url=(value)
        adaptation_sets.each { _1.base_url = value }
      end

      # Sets the segment query for all adaptation sets.
      #
      # @param value [String] The segment query to set.
      # @return [void]
      def segment_query=(value)
        adaptation_sets.each { _1.segment_query = value }
      end

      # Returns the MPD as a string in XML format.
      #
      # @return [String] The MPD document as a formatted XML string.
      def to_xml
        @document.to_xml(indent: 2, encoding: 'UTF-8')
      end

      # Returns the MPD as a string in M3U8 (HLS playlist) format.
      # NOTE: Currently only audio and video representations are supported.
      # Additionally only the first adaptation set of each type is included.
      #
      # See https://datatracker.ietf.org/doc/html/rfc8216
      #
      # @return [String] The MPD document as a formatted M3U8 string.
      def to_m3u8
        m3u8 = %w[#EXTM3U #EXT-X-VERSION:6]

        adaptation_sets =
          self
          .adaptation_sets
          .select(&:representations)
          .select { %w[audio video].include?(_1.content_type) }
          .uniq(&:content_type)
          .sort_by(&:content_type)

        # Add the EXT-X-MEDIA tag for the audio adaptation set only if there
        # are both audio and video adaptation sets present.
        if adaptation_sets.size.to_i > 1
          m3u8 <<
            adaptation_sets
            .first
            .to_m3u8mt(group_id: 'audio')
        end

        # Add the EXT-X-STREAM-INF tag for each audio or video representation.
        adaptation_sets.last&.representations&.each do |representation|
          m3u8 << representation.to_m3u8si(audio_group_id: adaptation_sets.size > 1 ? 'audio' : nil)
        end

        m3u8.compact.join("\n")
      end

      private

      def respond_to_missing?(name, include_private = false)
        @document.respond_to?(name, include_private) || super
      end

      def method_missing(name, *args, &)
        @document.send(name, *args, &)
      end
    end
  end
end
