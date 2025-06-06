# frozen_string_literal: true

require_relative '../../filter'
require_relative '../../filters/fps'
require_relative '../../filters/split'
require_relative '../dash'
require_relative '../h264'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Presets
    class DASH
      # rubocop:enable Style/Documentation
      class << self
        def h264_360p(
          name: 'DASH H.264 360p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          audio_bit_rate: '128k',
          frame_rate: 30,
          ld_frame_rate: 24,
          &
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
            keyframe_interval:,
            h264_presets: [
              Presets.h264_360p(audio_bit_rate:, frame_rate:)
            ],
            ld_h264_presets: [
              Presets.h264_240p(audio_bit_rate:, frame_rate: ld_frame_rate),
              Presets.h264_144p(audio_bit_rate:, frame_rate: ld_frame_rate)
            ],
            &
          )
        end

        def h264_480p(
          name: 'DASH H.264 480p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          audio_bit_rate: '128k',
          frame_rate: 30,
          ld_frame_rate: 24,
          &
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
            keyframe_interval:,
            h264_presets: [
              Presets.h264_480p(audio_bit_rate:, frame_rate:),
              Presets.h264_360p(audio_bit_rate:, frame_rate:)
            ],
            ld_h264_presets: [
              Presets.h264_240p(audio_bit_rate:, frame_rate: ld_frame_rate),
              Presets.h264_144p(audio_bit_rate:, frame_rate: ld_frame_rate)
            ],
            &
          )
        end

        def h264_720p(
          name: 'DASH H.264 720p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          audio_bit_rate: '128k',
          ld_frame_rate: 24,
          sd_frame_rate: 30,
          hd_frame_rate: 30,
          &
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            threads:,
            keyframe_interval:,
            segment_duration:,
            h264_presets: [
              Presets.h264_720p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_480p(audio_bit_rate:, frame_rate: sd_frame_rate),
              Presets.h264_360p(audio_bit_rate:, frame_rate: sd_frame_rate)
            ],
            ld_h264_presets: [
              Presets.h264_240p(audio_bit_rate:, frame_rate: ld_frame_rate),
              Presets.h264_144p(audio_bit_rate:, frame_rate: ld_frame_rate)
            ],
            &
          )
        end

        def h264_1080p(
          name: 'DASH H.264 1080p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          audio_bit_rate: '128k',
          ld_frame_rate: 24,
          sd_frame_rate: 30,
          hd_frame_rate: 30,
          &
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            threads:,
            keyframe_interval:,
            segment_duration:,
            h264_presets: [
              Presets.h264_1080p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_720p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_480p(audio_bit_rate:, frame_rate: sd_frame_rate),
              Presets.h264_360p(audio_bit_rate:, frame_rate: sd_frame_rate)
            ],
            ld_h264_presets: [
              Presets.h264_240p(audio_bit_rate:, frame_rate: ld_frame_rate),
              Presets.h264_144p(audio_bit_rate:, frame_rate: ld_frame_rate)
            ],
            &
          )
        end

        def h264_1440p(
          name: 'DASH H.264 1440p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          audio_bit_rate: '128k',
          ld_frame_rate: 24,
          sd_frame_rate: 30,
          hd_frame_rate: 30,
          &
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            threads:,
            keyframe_interval:,
            segment_duration:,
            h264_presets: [
              Presets.h264_1440p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_1080p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_720p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_480p(audio_bit_rate:, frame_rate: sd_frame_rate),
              Presets.h264_360p(audio_bit_rate:, frame_rate: sd_frame_rate)
            ],
            ld_h264_presets: [
              Presets.h264_240p(audio_bit_rate:, frame_rate: ld_frame_rate),
              Presets.h264_144p(audio_bit_rate:, frame_rate: ld_frame_rate)
            ],
            &
          )
        end

        def h264_4k(
          name: 'DASH H.264 4K',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          audio_bit_rate: '128k',
          ld_frame_rate: 24,
          sd_frame_rate: 30,
          hd_frame_rate: 60,
          uhd_frame_rate: 60,
          &
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
            keyframe_interval:,
            h264_presets: [
              Presets.h264_4k(audio_bit_rate:, frame_rate: uhd_frame_rate),
              Presets.h264_1440p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_1080p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_720p(audio_bit_rate:, frame_rate: hd_frame_rate),
              Presets.h264_480p(audio_bit_rate:, frame_rate: sd_frame_rate),
              Presets.h264_360p(audio_bit_rate:, frame_rate: sd_frame_rate)
            ],
            ld_h264_presets: [
              Presets.h264_240p(audio_bit_rate:, frame_rate: ld_frame_rate),
              Presets.h264_144p(audio_bit_rate:, frame_rate: ld_frame_rate)
            ],
            &
          )
        end
      end

      # Preset to encode DASH H.264 video files.
      class H264 < DASH
        attr_reader :keyframe_interval, :h264_presets, :ld_h264_presets

        # @param name [String] The name of the preset.
        # @param filename [String] The filename format of the output.
        # @param metadata [Object] The metadata to associate with the preset.
        # @param segment_duration [Integer] The duration of each segment in seconds.
        # @param keyframe_interval [Integer] The interval between keyframes in seconds.
        # @param h264_presets [Array<Presets::H264>] The H.264 presets to use for video streams and the audio stream.
        # @param ld_h264_presets [Array<Presets::H264>] The H.264 presets to use for low-definition video streams.
        # @yield The block to execute to compose the command arguments.
        def initialize(
          name: nil,
          filename: nil,
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          keyframe_interval: 2,
          h264_presets: [Presets.h264_1080p, Presets.h264_720p, Presets.h264_480p, Presets.h264_360p],
          ld_h264_presets: [Presets.h264_240p, Presets.h264_144p],
          &
        )
          unless h264_presets.is_a?(Array)
            raise ArgumentError, "Unknown h264_presets format #{h264_presets.class}, expected #{Array}"
          end

          h264_presets.each do |h264_preset|
            unless h264_preset.is_a?(Presets::H264)
              raise ArgumentError,
                    "Unknown h264_presets format #{h264_preset.class}, expected #{Array} of #{Presets::H264}"
            end
          end

          @keyframe_interval = keyframe_interval
          @h264_presets = h264_presets
          @ld_h264_presets = ld_h264_presets
          preset = self

          super(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
          ) do
            scene_change_threshold 0

            if media.video_streams? && media.audio_streams?
              adaptation_sets 'id=0,streams=v id=1,streams=a'
            elsif media.video_streams?
              adaptation_sets 'id=0,streams=v'
            elsif media.audio_streams?
              adaptation_sets 'id=0,streams=a'
            end

            video_codec_name 'libx264'
            audio_codec_name 'aac'

            instance_exec(&) if block_given?

            # Only include usable H.264 presets.
            h264_presets = preset.usable_h264_presets(media)

            if media.video_streams?
              # Use the highest quality H.264 preset, profile and constant rate factor
              # for all video representations, to make sure that the bitrates are
              # consistent across all representations.
              video_preset h264_presets.first.video_preset
              video_profile h264_presets.first.video_profile
              constant_rate_factor h264_presets.first.constant_rate_factor, stream_type: 'v'

              # Use the default video stream for all representations.
              h264_presets.each_with_index do |h264_preset, index|
                map media.video_mapping_id do
                  frame_rate = adjusted_frame_rate(h264_preset.frame_rate)
                  filters Filters.fps(frame_rate),
                          h264_preset.format_filter,
                          h264_preset.scale_filter(media),
                          h264_preset.dar_filter(media),
                          stream_index: index
                  min_keyframe_interval preset.keyframe_interval * frame_rate, stream_index: index
                  max_keyframe_interval preset.keyframe_interval * frame_rate, stream_index: index
                  force_keyframes "expr:gte(t,n_forced*#{preset.keyframe_interval})", stream_index: index
                end
              end
            end

            map media.audio_mapping_id do
              # Reset the audio stream's timestamps to start from 0.
              filter Filter.new(:audio, 'asetpts', expr: 'PTS-STARTPTS')
              audio_bit_rate h264_presets.first.audio_bit_rate
            end
          end
        end

        def usable_h264_presets(media)
          result = h264_presets.filter { |h264_preset| h264_preset.fits?(media) }
          return result unless result.empty?

          result = ld_h264_presets.filter { |h264_preset| h264_preset.fits?(media) }
          return result unless result.empty?

          [ld_h264_presets.last || h264_presets.last]
        end
      end
    end
  end
end
