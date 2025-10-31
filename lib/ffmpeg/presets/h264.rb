# frozen_string_literal: true

require_relative '../filters/scale'
require_relative '../preset'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Presets
    # rubocop:enable Style/Documentation
    class << self
      def h264_144p(
        name: 'H.264 144p',
        filename: '%<basename>s.144p.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'ultrafast',
        video_profile: 'baseline',
        frame_rate: 30,
        constant_rate_factor: 28,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 256,
          max_height: 144,
          &
        )
      end

      def h264_240p(
        name: 'H.264 240p',
        filename: '%<basename>s.240p.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'ultrafast',
        video_profile: 'baseline',
        frame_rate: 30,
        constant_rate_factor: 28,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 426,
          max_height: 240,
          &
        )
      end

      def h264_360p(
        name: 'H.264 360p',
        filename: '%<basename>s.360p.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'ultrafast',
        video_profile: 'baseline',
        frame_rate: 30,
        constant_rate_factor: 28,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 640,
          max_height: 360,
          &
        )
      end

      def h264_480p(
        name: 'H.264 480p',
        filename: '%<basename>s.480p.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'fast',
        video_profile: 'main',
        frame_rate: 30,
        constant_rate_factor: 27,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 854,
          max_height: 480,
          &
        )
      end

      def h264_720p(
        name: 'H.264 720p',
        filename: '%<basename>s.720p.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'fast',
        video_profile: 'high',
        frame_rate: 60,
        constant_rate_factor: 27,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 1280,
          max_height: 720,
          &
        )
      end

      def h264_1080p(
        name: 'H.264 1080p',
        filename: '%<basename>s.1080p.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'fast',
        video_profile: 'high',
        frame_rate: 60,
        constant_rate_factor: 27,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 1920,
          max_height: 1080,
          &
        )
      end

      def h264_1440p(
        name: 'H.264 2K',
        filename: '%<basename>s.2k.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'fast',
        video_profile: 'high',
        frame_rate: 60,
        constant_rate_factor: 26,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 2560,
          max_height: 1440,
          &
        )
      end

      def h264_4k(
        name: 'H.264 4K',
        filename: '%<basename>s.4k.mp4',
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'fast',
        video_profile: 'high',
        frame_rate: 60,
        constant_rate_factor: 26,
        pixel_format: 'yuv420p',
        &
      )
        H264.new(
          name:,
          filename:,
          metadata:,
          threads:,
          audio_bit_rate:,
          audio_sample_rate:,
          audio_channels:,
          video_preset:,
          video_profile:,
          frame_rate:,
          constant_rate_factor:,
          pixel_format:,
          max_width: 3840,
          max_height: 2160,
          &
        )
      end
    end

    # Preset to encode H.264 video files.
    class H264 < Preset
      attr_reader :threads, :audio_bit_rate, :audio_sample_rate, :audio_channels, :video_preset, :video_profile,
                  :frame_rate, :constant_rate_factor, :pixel_format,
                  :max_width, :max_height

      # @param name [String] The name of the preset.
      # @param filename [String] The filename format of the output.
      # @param metadata [Object] The metadata to associate with the preset.
      # @param audio_bit_rate [String] The audio bit rate to use.
      # @param audio_sample_rate [Integer] The audio sample rate to use.
      # @param audio_channels [Integer, nil] The number of audio channels to use (nil to preserve source).
      # @param video_preset [String] The video preset to use.
      # @param video_profile [String] The video profile to use.
      # @param frame_rate [Integer] The frame rate to use.
      # @param constant_rate_factor [Integer] The constant rate factor to use.
      # @param pixel_format [String] The pixel format to use.
      # @param max_width [Integer] The maximum width of the video.
      # @param max_height [Integer] The maximum height of the video.
      # @yield The block to execute to compose the command arguments.
      def initialize(
        name: nil,
        filename: nil,
        metadata: nil,
        threads: FFMPEG.threads,
        audio_bit_rate: '128k',
        audio_sample_rate: 48_000,
        audio_channels: 2,
        video_preset: 'fast',
        video_profile: 'high',
        frame_rate: 30,
        constant_rate_factor: 23,
        pixel_format: 'yuv420p',
        max_width: nil,
        max_height: nil,
        &
      )
        if max_width && !max_width.is_a?(Numeric)
          raise ArgumentError, "Unknown max_width format #{max_width.class}, expected #{Numeric}"
        end

        if max_height && !max_height.is_a?(Numeric)
          raise ArgumentError, "Unknown max_height format #{max_height.class}, expected #{Numeric}"
        end

        @threads = threads
        @audio_bit_rate = audio_bit_rate
        @audio_sample_rate = audio_sample_rate
        @audio_channels = audio_channels
        @video_preset = video_preset
        @video_profile = video_profile
        @frame_rate = frame_rate
        @constant_rate_factor = constant_rate_factor
        @pixel_format = pixel_format
        @max_width = max_width
        @max_height = max_height
        preset = self

        super(name:, filename:, metadata:) do
          threads preset.threads if preset.threads
          format_name 'mp4'
          muxing_flags '+faststart'
          map_chapters '-1'
          video_codec_name 'libx264'
          audio_codec_name 'aac'

          instance_exec(&) if block_given?

          map media.video_mapping_id do
            video_preset preset.video_preset
            video_profile preset.video_profile
            frame_rate preset.frame_rate
            constant_rate_factor preset.constant_rate_factor
            filters preset.format_filter, preset.scale_filter(media)
          end

          map media.audio_mapping_id do
            audio_bit_rate preset.audio_bit_rate
            audio_sample_rate preset.audio_sample_rate
            audio_channels preset.audio_channels if preset.audio_channels
          end
        end
      end

      def fits?(media)
        unless media.is_a?(FFMPEG::Media)
          raise ArgumentError, "Unknown media format #{media.class}, expected #{FFMPEG::Media}"
        end

        return false unless media.raw_width && media.raw_height

        if @max_width && @max_height
          media.raw_width >= @max_width || media.raw_height >= @max_height
        elsif @max_width
          media.raw_width >= @max_width
        elsif @max_height
          media.raw_height >= @max_height
        else
          true
        end
      end

      def format_filter
        Filters.format(pixel_formats: @pixel_format)
      end

      def scale_filter(media)
        return unless @max_width || @max_height

        Filters::Scale.contained(media, max_width: @max_width, max_height: @max_height)
      end

      def dar_filter(media)
        return unless media.display_aspect_ratio

        Filters.set_dar(media.display_aspect_ratio)
      end
    end
  end
end
