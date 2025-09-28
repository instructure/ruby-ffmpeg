# frozen_string_literal: true

require_relative 'raw_command_args'

module FFMPEG
  # A helper class for composing command arguments for FFMPEG.
  # It provides a DSL for setting arguments based on media properties.
  #
  # @example
  #  args = FFMPEG::CommandArgs.compose(media) do
  #    map media.video_mapping_id do
  #      video_codec_name 'libx264'
  #      frame_rate 30
  #    end
  #  end
  #  args.to_s # "-map 0:v:0 -c:v:0 libx264 -r 30"
  class CommandArgs < RawCommandArgs
    STANDARD_FRAME_RATES = [12, 24, 25, 30, 50, 60, 90, 120, 240].freeze

    class << self
      # Composes a new instance of CommandArgs with the given media.
      # The block is evaluated in the context of the new instance.
      #
      # @param media [FFMPEG::Media] The media to transcode.
      # @param context [Hash, nil] Additional context for composing the arguments.
      # # @return [FFMPEG::CommandArgs] The new FFMPEG::CommandArgs object.
      def compose(media, context: nil, &block)
        new(media, context:).tap do |args|
          args.instance_exec(&block) if block_given?
        end
      end
    end

    attr_reader :media

    # @param media [FFMPEG::Media] The media to transcode.
    # @param context [Hash, nil] Additional context for composing the arguments.
    def initialize(media, context: nil)
      @media = media
      super(context:)
    end

    # Sets the frame rate to the minimum of the current frame rate and the target value.
    #
    # @param target_value [Integer, Float] The target frame rate.
    # @return [self]
    def frame_rate(target_value)
      return self if target_value.nil?

      super(adjusted_frame_rate(target_value))
    end

    # Sets the video bit rate to the minimum of the current video bit rate and the target value.
    # The target value can be an Integer or a String (e.g.: 128k or 1M).
    #
    # @param target_value [Integer, String] The target bit rate.
    # @param kwargs [Hash] Additional options (see FFMPEG::RawCommandArgs#video_bit_rate).
    # @return [self]
    def video_bit_rate(target_value, **kwargs)
      return self if target_value.nil?

      super(adjusted_video_bit_rate(target_value), **kwargs)
    end

    # Sets the audio bit rate to the minimum of the current audio bit rate and the target value.
    # The target value can be an Integer or a String (e.g.: 128k or 1M).
    #
    # @param target_value [Integer, String] The target bit rate.
    # @return [self]
    def min_video_bit_rate(target_value)
      return self if target_value.nil?

      super(adjusted_video_bit_rate(target_value))
    end

    # Sets the audio bit rate to the minimum of the current audio bit rate and the target value.
    # The target value can be an Integer or a String (e.g.: 128k or 1M).
    #
    # @param target_value [Integer, String] The target bit rate.
    # @return [self]
    def max_video_bit_rate(target_value)
      return self if target_value.nil?

      super(adjusted_video_bit_rate(target_value))
    end

    # Sets the audio bit rate to the minimum of the current audio bit rate and the target value.
    # The target value can be an Integer or a String (e.g.: 128k or 1M).
    #
    # @param target_value [Integer, String] The target bit rate
    # @return [self]
    def audio_bit_rate(target_value, **kwargs)
      return self if target_value.nil?

      super(adjusted_audio_bit_rate(target_value), **kwargs)
    end

    # Returns the minimum of the current frame rate and the target value.
    #
    # @param target_value [Integer, Float] The target frame rate.
    # @return [Numeric]
    def adjusted_frame_rate(target_value)
      return target_value if media.frame_rate.nil?
      return target_value if media.frame_rate > target_value

      STANDARD_FRAME_RATES.min_by { (_1 - media.frame_rate).abs }
    end

    # Returns the minimum of the current video bit rate and the target value.
    # The target value can be an Integer or a String (e.g.: 128k or 1M).
    # The result is a String with the value in kilobits.
    #
    # @param target_value [Integer, String] The target video bit rate.
    # @return [String]
    def adjusted_video_bit_rate(target_value)
      min_bit_rate(media.video_bit_rate, target_value)
    end

    # Returns the minimum of the current audio bit rate and the target value.
    # The target value can be an Integer or a String (e.g.: 128k or 1M).
    # The result is a String with the value in kilobits.
    #
    # @param target_value [Integer, String] The target audio bit rate.
    # @return [String]
    def adjusted_audio_bit_rate(target_value)
      min_bit_rate(media.audio_bit_rate, target_value)
    end

    private

    def min_bit_rate(*values)
      bit_rate =
        values.filter_map do |value|
          # Some muxers (webm) might not expose birate under certain conditions
          next false if value.nil?
          next (value.positive? ? value : false) if value.is_a?(Integer)

          unless value.is_a?(String)
            raise ArgumentError,
                  "Unknown bit rate format #{value.class}, expected #{Integer} or #{String}"
          end

          match = value.match(/\A([1-9]\d*)([kM])\z/)
          unless match
            raise ArgumentError,
                  "Unknown bit rate format #{value}, expected [1-9]\\d*[kM]"
          end

          value = match[1].to_i
          case match[2]
          when 'k'
            value * 1_000
          when 'M'
            value * 1_000_000
          else
            value
          end
        end.min

      "#{(bit_rate.to_f / 1000).round}k"
    end
  end
end
