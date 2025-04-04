# frozen_string_literal: true

require_relative '../preset'

module FFMPEG
  module Presets
    # Preset to encode DASH media files.
    class DASH < Preset
      attr_reader :threads, :segment_duration

      # @param name [String] The name of the preset.
      # @param filename [String] The filename format of the output.
      # @param metadata [Object] The metadata to associate with the preset.
      # @param segment_duration [Integer] The duration of each segment in seconds.
      # @yield The block to execute to compose the command arguments.
      def initialize(
        name: nil,
        filename: nil,
        metadata: nil,
        threads: FFMPEG.threads,
        segment_duration: 4,
        &
      )
        @threads = threads
        @segment_duration = segment_duration
        preset = self

        super(name:, filename:, metadata:) do
          threads preset.threads if preset.threads
          format_name 'dash'
          segment_duration preset.segment_duration

          muxing_flags '+faststart'
          map_chapters '-1'

          instance_exec(&)
        end
      end
    end
  end
end
