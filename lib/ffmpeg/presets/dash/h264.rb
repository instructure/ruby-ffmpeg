# frozen_string_literal: true

require_relative '../../filter'
require_relative '../../filters/fps'
require_relative '../../filters/scale'
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
          audio_bit_rate: '128k',
          frame_rate: 30
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            audio_bit_rate:,
            h264_presets: [Presets.h264_360p(frame_rate:)]
          )
        end

        def h264_480p(
          name: 'DASH H.264 480p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          audio_bit_rate: '128k',
          frame_rate: 30
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            audio_bit_rate:,
            h264_presets: [
              Presets.h264_480p(frame_rate:),
              Presets.h264_360p(frame_rate:)
            ]
          )
        end

        def h264_720p(
          name: 'DASH H.264 720p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          audio_bit_rate: '128k',
          sd_frame_rate: 30,
          hd_frame_rate: 30
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            audio_bit_rate:,
            h264_presets: [
              Presets.h264_720p(frame_rate: hd_frame_rate),
              Presets.h264_480p(frame_rate: sd_frame_rate),
              Presets.h264_360p(frame_rate: sd_frame_rate)
            ]
          )
        end

        def h264_1080p(
          name: 'DASH H.264 1080p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          audio_bit_rate: '128k',
          sd_frame_rate: 30,
          hd_frame_rate: 30
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            audio_bit_rate:,
            h264_presets: [
              Presets.h264_1080p(frame_rate: hd_frame_rate),
              Presets.h264_720p(frame_rate: hd_frame_rate),
              Presets.h264_480p(frame_rate: sd_frame_rate),
              Presets.h264_360p(frame_rate: sd_frame_rate)
            ]
          )
        end

        def h264_1440p(
          name: 'DASH H.264 1440p',
          filename: '%<basename>s.mpd',
          metadata: nil,
          audio_bit_rate: '128k',
          sd_frame_rate: 30,
          hd_frame_rate: 30
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            audio_bit_rate:,
            h264_presets: [
              Presets.h264_1440p(frame_rate: hd_frame_rate),
              Presets.h264_1080p(frame_rate: hd_frame_rate),
              Presets.h264_720p(frame_rate: hd_frame_rate),
              Presets.h264_480p(frame_rate: sd_frame_rate),
              Presets.h264_360p(frame_rate: sd_frame_rate)
            ]
          )
        end

        def h264_4k(
          name: 'DASH H.264 4K',
          filename: '%<basename>s.mpd',
          metadata: nil,
          audio_bit_rate: '128k',
          sd_frame_rate: 30,
          hd_frame_rate: 30,
          uhd_frame_rate: 30
        )
          H264.new(
            name:,
            filename:,
            metadata:,
            audio_bit_rate:,
            h264_presets: [
              Presets.h264_4k(frame_rate: uhd_frame_rate),
              Presets.h264_1440p(frame_rate: hd_frame_rate),
              Presets.h264_1080p(frame_rate: hd_frame_rate),
              Presets.h264_720p(frame_rate: hd_frame_rate),
              Presets.h264_480p(frame_rate: sd_frame_rate),
              Presets.h264_360p(frame_rate: sd_frame_rate)
            ]
          )
        end
      end

      # Preset to encode DASH H.264 video files.
      class H264 < DASH
        attr_reader :audio_bit_rate, :h264_presets

        # @param name [String] The name of the preset.
        # @param filename [String] The filename format of the output.
        # @param metadata [Object] The metadata to associate with the preset.
        # @param audio_bit_rate [String] The audio bit rate to use.
        # @param h264_presets [Array<Presets::H264>] The H.264 presets to use for video streams.
        # @yield The block to execute to compose the command arguments.
        def initialize(
          name: nil,
          filename: nil,
          metadata: nil,
          audio_bit_rate: '128k',
          h264_presets: [Presets.h264_1080p, Presets.h264_720p, Presets.h264_480p, Presets.h264_360p],
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

          @audio_bit_rate = audio_bit_rate
          @h264_presets = h264_presets
          preset = self

          super(name:, filename:, metadata:) do
            video_codec_name 'libx264'
            audio_codec_name 'aac'

            instance_exec(&) if block_given?

            if media.video_streams?
              # Only include H.264 presets that the media fits within.
              h264_presets = preset.h264_presets.filter { |h264_preset| h264_preset.fits?(media) }

              # Split the default video stream into multiple streams,
              # one for each H.264 preset (e.g.: [v:0]split=2[v0][v1]).
              split_filter =
                Filters.split(h264_presets.length)
                       .with_input_link!(media.video_mapping_id)
                       .with_output_links!(*h264_presets.each_with_index.map { |_, index| "v#{index}" })

              # Scale the split video streams to the desired resolutions
              # and frame rates (e.g.: [v0]scale=640:360,fps=30[v0out]).
              scale_filter_graphs =
                h264_presets.each_with_index.map do |h264_preset, index|
                  Filter.join(
                    h264_preset
                      .scale_filter(media)
                      .with_input_link!("v#{index}"),
                    Filters.fps(adjusted_frame_rate(h264_preset.frame_rate))
                      .with_output_link!("v#{index}out")
                  )
                end

              # Apply the generated filter complex to the output.
              filter_complex split_filter, *scale_filter_graphs

              # Map the scaled video streams with the desired H.264 parameters.
              h264_presets.each_with_index do |h264_preset, index|
                map "[v#{index}out]" do
                  video_preset h264_preset.video_preset, stream_index: index
                  video_profile h264_preset.video_profile, stream_index: index
                  constant_rate_factor h264_preset.constant_rate_factor, stream_id: "v:#{index}"
                  pixel_format h264_preset.pixel_format
                end
              end
            end

            map media.audio_mapping_id do
              audio_bit_rate preset.audio_bit_rate
            end
          end
        end
      end
    end
  end
end
