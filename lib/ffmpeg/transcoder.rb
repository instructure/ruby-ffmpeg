# frozen_string_literal: true

require 'timeout'

require_relative 'media'
require_relative 'preset'

module FFMPEG
  # The Transcoder class is responsible for transcoding multimedia files.
  # It accepts a Media object or a path to a multimedia file as input.
  class Transcoder
    class Status
      attr_reader :paths

      def initialize(process_status, paths)
        @process_status = process_status
        @paths = paths
      end

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

    def initialize(name: nil, metadata: nil, presets: [], reporters: nil)
      @name = name
      @metadata = metadata
      @presets = presets
      @reporters = reporters
    end

    def extend(name: nil, metadata: nil, presets: [], reporters: nil)
      self.class.new(
        name: name || @name,
        metadata: metadata || @metadata,
        presets: presets + @presets,
        reporters: reporters || @reporters
      )
    end

    def process(media, output_path, inargs: [], &block)
      media = Media.new(media, load: false) unless media.is_a?(Media)

      output_paths = []
      output_path = Pathname.new(output_path)
      output_dir = output_path.dirname
      output_filename_kwargs = {
        basename: output_path.basename(output_path.extname),
        extname: output_path.extname,
        random: SecureRandom.hex(4)
      }

      args = []
      @presets.each do |preset|
        filename = preset.filename(**output_filename_kwargs)
        args += preset.args
        args << (filename.empty? ? output_path.to_s : output_dir.join(filename).to_s)
        output_paths << args.last
      end

      FFMPEG.logger.info(self.class) do
        "ffmpeg: Transcoding #{media.path} to #{output_path} (via #{@presets.map { |p| p.name || p.to_s }.join(' / ')})"
      end

      Status.new(
        media.ffmpeg_execute(*args, inargs: inargs, reporters: @reporters, &block),
        output_paths
      )
    end
  end
end
