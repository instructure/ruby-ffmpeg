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

      # Returns the adaptation sets in the MPD.
      #
      # @return [Array<AdaptationSet>, nil] An array of AdaptationSet objects.
      def adaptation_sets
        @adaptation_sets ||= @mpd&.xpath('./xmlns:Period[1]/xmlns:AdaptationSet')&.map(&AdaptationSet.method(:new))
      end

      # Sets the base URL for all adaptation sets.
      #
      # @param value [String] The base URL to set.
      # @return [void]
      def base_url=(value)
        adaptation_sets&.each { _1.base_url = value }
      end

      # Sets the segment query for all adaptation sets.
      #
      # @param value [String] The segment query to set.
      # @return [void]
      def segment_query=(value)
        adaptation_sets&.each { _1.segment_query = value }
      end

      # Returns the MPD as a string in XML format.
      #
      # @return [String] The MPD document as a formatted XML string.
      def to_s
        @document.to_xml(indent: 2, encoding: 'UTF-8')
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
