# frozen_string_literal: true

require 'etc'

require_relative '../preset'

module FFMPEG
  module Presets
    # Preset to encode DASH media files.
    class DASH < Preset
      # @param name [String] The name of the preset.
      # @param filename [String] The filename format of the output.
      # @param metadata [Object] The metadata to associate with the preset.
      # @yield The block to execute to compose the command arguments.
      def initialize(
        name: nil,
        filename: nil,
        metadata: nil,
        &
      )
        super(name:, filename:, metadata:) do
          format_name 'dash'
          adaptation_sets 'id=0,streams=v id=1,streams=a'
          segment_duration 2
          min_keyframe_interval 48
          max_keyframe_interval 48
          scene_change_threshold 0

          muxing_flags '+faststart'
          map_chapters '-1'

          instance_exec(&)
        end
      end
    end
  end
end
