# frozen_string_literal: true

require_relative 'filter'

module FFMPEG
  # A helper class for composing raw command arguments for FFMPEG.
  # It provides a DSL for setting arguments.
  #
  # @example
  #  args = FFMPEG::RawCommandArgs.compose do
  #    video_codec_name 'libx264'
  #    audio_codec_name 'aac'
  #  end
  #  args.to_s # "-c:v libx264 -c:a aac"
  class RawCommandArgs
    class << self
      # Compose a new set of command arguments with the specified block.
      # The block is executed in the context of the new set of command arguments.
      # When calling unknown methods on the new set of command arguments,
      # the method is treated as a new argument to add to the command arguments.
      #
      # @param block_args [Array] The arguments to pass to the block.
      # @yield The block to execute to compose the command arguments.
      # @return [FFMPEG::RawCommandArgs] The new set of raw command arguments.
      #
      # @example
      #  args = FFMPEG::RawCommandArgs.compose do
      #    video_codec_name 'libx264'
      #    audio_codec_name 'aac'
      #  end
      #  args.to_s # => "-c:v libx264 -c:a aac"
      def compose(*block_args, &)
        new.tap do |args|
          args.instance_exec(*block_args, &) if block_given?
        end
      end

      # Format the specified flags into a string.
      #
      # @param flags [Array] The flags to format.
      # @param separator [String] The separator to use between flags.
      # @param escape [Boolean] Whether to escape the flags or not (default: true).
      #
      # @example
      #  FFMPEG::RawCommandArgs.format_flags(['fast', 'superfast']) # => "fast|superfast"
      def format_flags(flags, separator: '|', escape: true)
        return '' if flags.nil?

        raise ArgumentError, "Unknown flags format #{flags.class}, expected #{Array}" unless flags.is_a?(Array)

        flags = escape ? flags.map(&method(:escape_graph_component)) : flags.map(&:to_s)
        flags.join(separator)
      end

      # Format the specified keyword arguments into a string.
      # The keyword arguments are formatted as key-value pairs
      # for a ffmpeg command.
      #
      # @param kwargs [Hash] The keyword arguments to format.
      # @param separator [String] The separator to use between key-value pairs.
      # @param escape [Boolean] Whether to escape the values or not (default: true).
      #
      # @example
      #  FFMPEG::RawCommandArgs.format_kwargs(bit_rate: '128k', profile: 'high') # => "bit_rate=128k:profile=high"
      def format_kwargs(kwargs, separator: ':', escape: true)
        return '' if kwargs.nil?

        raise ArgumentError, "Unknown kwargs format #{kwargs.class}, expected #{Hash}" unless kwargs.is_a?(Hash)

        kwargs.each_with_object([]) do |(key, value), acc|
          if value.nil?
            next acc
          elsif value.is_a?(Array)
            acc << "#{key}=#{format_flags(value, escape:)}"
          else
            value = escape_graph_component(value) if escape
            acc << "#{key}=#{value}"
          end
        end.join(separator)
      end

      private

      def escape_graph_component(value)
        value = value.to_s
        value =~ /[\\'\[\]=:|;,]/ ? "'#{value.gsub(/([\\'])/, '\\\\\1')}'" : value
      end
    end

    def initialize
      @args = []
    end

    # Returns the array representation of the command arguments.
    def to_a
      @args
    end

    # ==================== #
    # === COMMON UTILS === #
    # ==================== #

    # Add a new argument to the command arguments.
    #
    # @param name [String] The name of the argument.
    # @param value [Object] The value of the argument.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    arg 'c:v', 'libx264'
    #  end
    #  args.to_s # "-c:v libx264"
    def arg(name, value = nil)
      value =
        if value.is_a?(Hash)
          self.class.format_kwargs(value)
        elsif value.is_a?(Array)
          self.class.format_flags(value)
        else
          value&.to_s
        end

      @args << "-#{name}"
      @args << value if value

      self
    end

    # Adds a new stream specific argument to the command arguments.
    #
    # @param name [String] The name of the argument.
    # @param value [Object] The value of the argument.
    # @param stream_id [String] The stream ID to target (preferred over stream type and index).
    # @param stream_type [String] The stream type to target.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    stream_arg 'c', 'libx264', stream_id: 'v:0'
    #  end
    #  args.to_s # "-c:v:0 libx264"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    stream_arg 'c', 'libx264', stream_type: 'v', stream_index: 0
    #  end
    #  args.to_s # "-c:v:0 libx264"
    def stream_arg(name, value, stream_id: nil, stream_type: nil, stream_index: nil)
      if stream_id
        arg("#{name}:#{stream_id}", value)
      elsif stream_type && stream_index
        arg("#{name}:#{stream_type}:#{stream_index}", value)
      elsif stream_type
        arg("#{name}:#{stream_type}", value)
      elsif stream_index
        arg("#{name}:#{stream_index}", value)
      else
        arg(name, value)
      end
    end

    # Adds a new raw argument to the command arguments.
    #
    # @param value [Object] The argument.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    raw_arg '-vn'
    #    raw_arg '-an'
    #  end
    #  args.to_s # "-vn -an"
    def raw_arg(value)
      @args << value.to_s

      self
    end

    # Maps the specified stream ID to the output.
    # If a block is given, the block is executed right
    # after the -map argument is added.
    # This allows for adding stream specific arguments.
    #
    # @param stream_id [String] The stream ID to map.
    # @yield The block to execute to compose the stream specific arguments.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    map 'v:0' do
    #      video_codec_name 'libx264'
    #    end
    #  end
    #  args.to_s # "-map 0:v:0 -c:v libx264"
    def map(stream_id)
      return if stream_id.nil?

      arg('map', stream_id.to_s)

      yield if block_given?

      self
    end

    # Adds a new filter to the command arguments.
    #
    # @param filter [FFMPEG::Filter] The filter to add.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    filter FFMPEG::Filters.scale(width: -2, height: 1080)
    #  end
    #  args.to_s # "-vf scale=w=-2:h=1080"
    def filter(filter)
      filters(filter)
    end

    # Adds multiple filters to the command arguments
    # in a single filter chain.
    #
    # @param filters [Array<FFMPEG::Filter>] The filters to add.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    filters FFMPEG::Filters.scale(width: -2, height: 1080),
    #            FFMPEG::Filters.fps(24),
    #            FFMPEG::Filters.silence_detect
    #  end
    #  args.to_s # "-vf scale=w=-2:h=1080,fps=24 -af silencedetect"
    def filters(*filters)
      filters.compact.group_by(&:type).each do |type, group|
        arg("#{type.to_s[0]}f", Filter.join(*group))
      end

      self
    end

    # Adds a new bitstream filter to the command arguments.
    #
    # @param filter [FFMPEG::Filter] The bitstream filter to add.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    bitstream_filter FFMPEG::Filter.new(:video, 'h264_mp4toannexb')
    #  end
    #  args.to_s # "-bsf:v h264_mp4toannexb"
    def bitstream_filter(filter)
      bitstream_filters(filter)
    end

    # Adds multiple bitstream filters to the command arguments.
    #
    # @param filters [Array<FFMPEG::Filter>] The bitstream filters to add.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    bitstream_filters FFMPEG::Filter.new(:video, 'h264_mp4toannexb'),
    #                      FFMPEG::Filter.new(:audio, 'aac_adtstoasc')
    #  end
    #  args.to_s # "-bsf:v h264_mp4toannexb -bsf:a aac_adtstoasc"
    def bitstream_filters(*filters)
      filters.compact.group_by(&:type).each do |type, group|
        arg("bsf:#{type.to_s[0]}", Filter.join(*group))
      end

      self
    end

    # Adds a new filter complex to the command arguments.
    #
    # @param filters [Array<FFMPEG::Filter, String>] The filters to add.
    # @return [self]
    def filter_complex(*filters)
      arg('filter_complex', filters.compact.map(&:to_s).join(';'))

      self
    end

    # Sets the output format in the command arguments.
    #
    # @param value [String] The format to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #   output_format 'dash'
    #  end
    #  args.to_s # "-f dash"
    def format_name(value)
      arg('f', value)
    end

    # Adds new muxing flags in the command arguments.
    #
    # @param value [String] The flags to add.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    muxing_flags '+faststart+frag_keyframe'
    #  end
    #  args.to_s # "-movflags +faststart+frag_keyframe"
    def muxing_flags(value)
      arg('movflags', value)
    end

    # Sets the buffer size in the command arguments.
    #
    # @param value [String, Numeric] The buffer size to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    buffer_size '64k'
    #  end
    #  args.to_s # "-bufsize 64k"
    def buffer_size(value)
      arg('bufsize', value)
    end

    # Sets the duration in the command arguments.
    #
    # @param value [String, Numeric] The duration to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    duration 10
    #  end
    #  args.to_s # "-t 10"
    def duration(value)
      arg('t', value)
    end

    # Sets the segment duration in the command arguments.
    # This is used for adaptive streaming.
    #
    # @param value [String, Numeric] The segment duration to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    segment_duration 2
    #  end
    #  args.to_s # "-seg_duration 2"
    def segment_duration(value)
      arg('seg_duration', value)
    end

    # Sets a constant rate factor in the command arguments.
    #
    # @param value [String, Numeric] The constant rate factor to set.
    # @param kwargs [Hash] The stream specific arguments to use (see stream_arg).
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    constant_rate_factor 23
    #  end
    #  args.to_s # "-crf 23"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    constant_rate_factor 23, stream_id: 'v:0'
    #  end
    #  args.to_s # "-crf:v:0 23"
    def constant_rate_factor(value, **kwargs)
      stream_arg('crf', value, **kwargs)
    end

    # =================== #
    # === VIDEO UTILS === #
    # =================== #

    # Sets a video codec in the command arguments.
    #
    # @param value [String] The video codec to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_codec_name 'libx264'
    #  end
    #  args.to_s # "-c:v libx264"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_codec_name 'libx264', stream_index: 0
    #  end
    #  args.to_s # "-c:v:0 libx264"
    def video_codec_name(value, stream_index: nil)
      stream_arg('c', value, stream_type: 'v', stream_index:)
    end

    # Sets a video bit rate in the command arguments.
    #
    # @param value [String, Numeric] The video bit rate to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_bit_rate '128k'
    #  end
    #  args.to_s # "-b:v 128k"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_bit_rate '128k', stream_index: 0
    #  end
    #  args.to_s # "-b:v:0 128k"
    def video_bit_rate(value, stream_index: nil)
      stream_arg('b', value, stream_type: 'v', stream_index:)
    end

    # Sets a minimum video bit rate in the command arguments.
    #
    # @param value [String, Numeric] The minimum video bit rate to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    min_video_bit_rate '128k'
    #  end
    #  args.to_s # "-minrate 128k"
    def min_video_bit_rate(value)
      arg('minrate', value)
    end

    # Sets a maximum video bit rate in the command arguments.
    #
    # @param value [String, Numeric] The maximum video bit rate to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    max_video_bit_rate '128k'
    #  end
    #  args.to_s # "-maxrate 128k"
    def max_video_bit_rate(value)
      arg('maxrate', value)
    end

    # Sets a video preset in the command arguments.
    #
    # @param value [String] The video preset to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_preset 'fast'
    #  end
    #  args.to_s # "-preset:v fast"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_preset 'fast', stream_index: 0
    #  end
    #  args.to_s # "-preset:v:0 fast"
    def video_preset(value, stream_index: nil)
      stream_arg('preset', value, stream_type: 'v', stream_index:)
    end

    # Sets a video profile in the command arguments.
    #
    # @param value [String] The video profile to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_profile 'high'
    #  end
    #  args.to_s # "-profile:v high"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_profile 'high', stream_index: 0
    #  end
    #  args.to_s # "-profile:v:0 high"
    def video_profile(value, stream_index: nil)
      stream_arg('profile', value, stream_type: 'v', stream_index:)
    end

    # Sets a video quality in the command arguments.
    #
    # @param value [String] The video quality to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_quality '2'
    #  end
    #  args.to_s # "-q:v 2"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    video_quality '2', stream_index: 0
    #  end
    #  args.to_s # "-q:v:0 2"
    def video_quality(value, stream_index: nil)
      stream_arg('q', value, stream_type: 'v', stream_index:)
    end

    # Sets a frame rate in the command arguments.
    #
    # @param value [String, Numeric] The frame rate to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    frame_rate 30
    #  end
    #  args.to_s # "-r 30"
    def frame_rate(value)
      arg('r', value)
    end

    # Sets a pixel format in the command arguments.
    #
    # @param value [String] The pixel format to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    pixel_format 'yuv420p'
    #  end
    #  args.to_s # "-pix_fmt yuv420p"
    def pixel_format(value)
      arg('pix_fmt', value)
    end

    # Sets a resolution in the command arguments.
    #
    # @param value [String] The resolution to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    resolution '1920x1080'
    #  end
    #  args.to_s # "-s 1920x1080"
    def resolution(value)
      arg('s', value)
    end

    # Sets an aspect ratio in the command arguments.
    #
    # @param value [String] The aspect ratio to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    aspect_ratio '16:9'
    #  end
    #  args.to_s # "-aspect 16:9"
    def aspect_ratio(value)
      arg('aspect', value)
    end

    # Sets a minimum keyframe interval in the command arguments.
    # This is used for adaptive streaming.
    #
    # @param value [String, Numeric] The minimum keyframe interval to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    min_keyframe_interval 48
    #  end
    #  args.to_s # "-keyint_min 48"
    def min_keyframe_interval(value)
      arg('keyint_min', value)
    end

    # Sets a maximum keyframe interval in the command arguments.
    #
    # This is used for adaptive streaming.
    # @param value [String, Numeric] The maximum keyframe interval to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    max_keyframe_interval 48
    #  end
    #  args.to_s # "-g 48"
    def max_keyframe_interval(value)
      arg('g', value)
    end

    # Sets a scene change threshold in the command arguments.
    # This is used for adaptive streaming.
    #
    # @param value [String, Numeric] The scene change threshold to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    scene_change_threshold 0
    #  end
    #  args.to_s # "-sc_threshold 0"
    def scene_change_threshold(value)
      arg('sc_threshold', value)
    end

    # =================== #
    # === AUDIO UTILS === #
    # =================== #

    # Sets an audio codec in the command arguments.
    #
    # @param value [String] The audio codec to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_codec_name 'aac'
    #  end
    #  args.to_s # "-c:a aac"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_codec_name 'aac', stream_index: 0
    #  end
    #  args.to_s # "-c:a:0 aac"
    def audio_codec_name(value, stream_index: nil)
      stream_arg('c', value, stream_type: 'a', stream_index:)
    end

    # Sets an audio bit rate in the command arguments.
    #
    # @param value [String, Numeric] The audio bit rate to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_bit_rate '128k'
    #  end
    #  args.to_s # "-b:a 128k"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_bit_rate '128k', stream_index: 0
    #  end
    #  args.to_s # "-b:a:0 128k"
    def audio_bit_rate(value, stream_index: nil)
      stream_arg('b', value, stream_type: 'a', stream_index:)
    end

    # Sets an audio sample rate in the command arguments.
    #
    # @param value [String, Numeric] The audio sample rate to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_sample_rate 44100
    #  end
    #  args.to_s # "-ar 44100"
    def audio_sample_rate(value)
      arg('ar', value)
    end

    # Sets the number of audio channels in the command arguments.
    #
    # @param value [String, Numeric] The number of audio channels to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_channels 2
    #  end
    #  args.to_s # "-ac 2"
    def audio_channels(value)
      arg('ac', value)
    end

    # Sets an audio preset in the command arguments.
    #
    # @param value [String] The audio preset to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_preset 'aac_low'
    #  end
    #  args.to_s # "-profile:a aac_low"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_preset 'aac_low', stream_index: 0
    #  end
    #  args.to_s # "-profile:a:0 aac_low"
    def audio_preset(value, stream_index: nil)
      stream_arg('preset', value, stream_type: 'a', stream_index:)
    end

    # Sets an audio profile in the command arguments.
    #
    # @param value [String] The audio profile to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_profile 'aac_low'
    #  end
    #  args.to_s # "-profile:a aac_low"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_profile 'aac_low', stream_index: 0
    #  end
    #  args.to_s # "-profile:a:0 aac_low"
    def audio_profile(value, stream_index: nil)
      stream_arg('profile', value, stream_type: 'a', stream_index:)
    end

    # Sets an audio quality in the command arguments.
    #
    # @param value [String] The audio quality to set.
    # @param stream_index [String] The stream index to target.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_quality '2'
    #  end
    #  args.to_s # "-q:a 2"
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_quality '2', stream_index: 0
    #  end
    #  args.to_s # "-q:a:0 2"
    def audio_quality(value, stream_index: nil)
      stream_arg('q', value, stream_type: 'a', stream_index:)
    end

    # Sets the audio sync in the command arguments.
    # This is used to synchronize audio and video streams.
    #
    # @param value [String, Numeric] The audio sync to set.
    # @return [self]
    #
    # @example
    #  args = FFMPEG::RawCommandArgs.compose do
    #    audio_sync 1
    #  end
    #  args.to_s # "-async 1"
    def audio_sync(value)
      arg('async', value)
    end

    private

    def respond_to_missing?
      true
    end

    def method_missing(name, *args)
      arg(name, args.first)
    end
  end
end
