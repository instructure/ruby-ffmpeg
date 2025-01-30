# frozen_string_literal: true

require 'etc'

require_relative '../preset'

module FFMPEG
  module Presets
    # Preset to encode DASH media files.
    class DASH < Preset
      attr_reader :segment_duration, :min_keyframe_interval, :max_keyframe_interval, :scene_change_threshold

      # @param name [String] The name of the preset.
      # @param filename [String] The filename format of the output.
      # @param metadata [Object] The metadata to associate with the preset.
      # @param segment_duration [Integer] The duration of each segment in seconds.
      # @param min_keyframe_interval [Integer] The minimum keyframe interval in frames.
      # @param max_keyframe_interval [Integer] The maximum keyframe interval in frames.
      # @param scene_change_threshold [Integer] The scene change threshold.
      # @yield The block to execute to compose the command arguments.
      def initialize(
        name: nil,
        filename: nil,
        metadata: nil,
        segment_duration: 2,
        min_keyframe_interval: 48,
        max_keyframe_interval: 48,
        scene_change_threshold: 0,
        &
      )
        @segment_duration = segment_duration
        @min_keyframe_interval = min_keyframe_interval
        @max_keyframe_interval = max_keyframe_interval
        @scene_change_threshold = scene_change_threshold
        preset = self

        super(name:, filename:, metadata:) do
          format_name 'dash'
          adaptation_sets 'id=0,streams=v id=1,streams=a'
          segment_duration preset.segment_duration
          min_keyframe_interval preset.min_keyframe_interval
          max_keyframe_interval preset.max_keyframe_interval
          scene_change_threshold preset.scene_change_threshold

          muxing_flags '+faststart'
          map_chapters '-1'

          instance_exec(&)
        end
      end
    end
  end
end
