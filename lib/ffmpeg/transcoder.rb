# frozen_string_literal: true

require 'timeout'

require_relative 'media'

module FFMPEG
  # The Transcoder class is responsible for transcoding multimedia files
  # via preset configurations.
  #
  # @example
  #  transcoder = FFMPEG::Transcoder.new(
  #    presets: [FFMPEG::Presets.h264_360p_30, FFMPEG::Presets.aac_128k]
  #  )
  #  status = transcoder.process('input.mp4', 'output') do |report|
  #    puts(report)
  #  end
  #  status.paths # ['output.360p30.mp4', 'output.128k.aac']
  #  status.media # [FFMPEG::Media, FFMPEG::Media]
  #  status.success? # true
  #  status.exitstatus # 0
  class Transcoder
    # The Status class represents the status of a transcoding process.
    # It inherits all methods from the Process::Status class.
    # It also provides a method to retrieve the media files associated with
    # the transcoding process.
    class Status
      attr_reader :paths

      def initialize(process_status, paths)
        @process_status = process_status
        @paths = paths
      end

      # Returns the media files associated with the transcoding process.
      #
      # @param ffprobe_args [Array<String>] The arguments to pass to ffprobe.
      # @param load [Boolean] Whether to load the media files.
      # @param autoload [Boolean] Whether to autoload the media files.
      # @return [Array<FFMPEG::Media>] The media files.
      def media(*ffprobe_args, load: true, autoload: true)
        @paths.map do |path|
          Media.new(path, *ffprobe_args, load: load, autoload: autoload)
        end
      end

      private

      def respond_to_missing?(symbol, include_private)
        @process_status.respond_to?(symbol, include_private)
      end

      def method_missing(symbol, *args)
        @process_status.send(symbol, *args)
      end
    end

    attr_reader :name, :metadata, :presets, :reporters

    def initialize(name: nil, metadata: nil, presets: [], reporters: [Reporters::Progress], &compose_inargs)
      @name = name
      @metadata = metadata
      @presets = presets
      @reporters = reporters
      @compose_inargs = compose_inargs
    end

    # Transcodes the media file using the preset configurations.
    #
    # @param media [String, Pathname, URI, FFMPEG::Media] The media file to transcode.
    # @param output_path [String, Pathname] The output path to save the transcoded files.
    # @yield The block to execute to report the transcoding process.
    # @return [FFMPEG::Transcoder::Status] The status of the transcoding process.
    def process(media, output_path, &)
      media = Media.new(media, load: false) unless media.is_a?(Media)

      output_paths = []
      output_path = Pathname.new(output_path)
      output_dir = output_path.dirname
      output_filename_kwargs = {
        basename: output_path.basename(output_path.extname),
        extname: output_path.extname
      }

      args = []
      @presets.each do |preset|
        filename = preset.filename(**output_filename_kwargs)
        args += preset.args(media)
        args << (filename.nil? ? output_path.to_s : output_dir.join(filename).to_s)
        output_paths << args.last
      end

      inargs = CommandArgs.compose(media, &@compose_inargs).to_a

      Status.new(
        media.ffmpeg_execute(*args, inargs: inargs, reporters: @reporters, &),
        output_paths
      )
    end
  end
end
