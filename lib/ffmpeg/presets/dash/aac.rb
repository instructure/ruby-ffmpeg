# frozen_string_literal: true

require_relative '../dash'

module FFMPEG
  # rubocop:disable Style/Documentation
  module Presets
    class DASH
      # rubocop:enable Style/Documentation
      class << self
        def aac_128k(
          name: 'DASH AAC 128k',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          &
        )
          AAC.new(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
            audio_bit_rate: '128k',
            &
          )
        end

        def aac_192k(
          name: 'DASH AAC 192k',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          &
        )
          AAC.new(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
            audio_bit_rate: '192k',
            &
          )
        end

        def aac_320k(
          name: 'DASH AAC 320k',
          filename: '%<basename>s.mpd',
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          &
        )
          AAC.new(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:,
            audio_bit_rate: '320k',
            &
          )
        end
      end

      # Preset to encode DASH AAC audio files.
      class AAC < DASH
        attr_reader :audio_bit_rate

        # @param name [String] The name of the preset.
        # @param filename [String] The filename format of the output.
        # @param metadata [Object] The metadata to associate with the preset.
        # @param audio_bit_rate [String] The audio bit rate to use.
        # @yield The block to execute to compose the command arguments.
        def initialize(
          name: nil,
          filename: nil,
          metadata: nil,
          threads: FFMPEG.threads,
          segment_duration: 4,
          audio_bit_rate: '128k',
          &
        )
          @audio_bit_rate = audio_bit_rate
          preset = self

          super(
            name:,
            filename:,
            metadata:,
            threads:,
            segment_duration:
          ) do
            adaptation_sets 'id=0,streams=a' if media.audio_streams?

            audio_codec_name 'aac'

            instance_exec(&) if block_given?

            map media.audio_mapping_id do
              audio_bit_rate preset.audio_bit_rate
            end
          end
        end
      end
    end
  end
end
