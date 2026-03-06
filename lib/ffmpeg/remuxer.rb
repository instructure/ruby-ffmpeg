# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require_relative 'media'

module FFMPEG
  # The Remuxer class is responsible for remuxing multimedia files via stream copy.
  # It attempts a direct stream copy first, and if that fails (e.g. due to corrupted
  # timestamps), it falls back to extracting raw Annex B streams and re-muxing them
  # with a corrected frame rate.
  #
  # @example
  #  remuxer = FFMPEG::Remuxer.new
  #  status = remuxer.process('input.mp4', 'output.mp4')
  #  status.success? # => true
  class Remuxer
    ANNEXB_CODEC_NAMES = %w[h264 hevc].freeze

    # @param name [String, nil] An optional name for the remuxer.
    # @param metadata [Hash, nil] Optional metadata to associate with the remuxer.
    # @param checks [Array<Symbol, Proc>] Checks to run on the output to determine success.
    # @param timeout [Integer, nil] Timeout in seconds for each ffmpeg command.
    def initialize(name: nil, metadata: nil, checks: %i[exist?], timeout: nil)
      @name = name
      @metadata = metadata
      @checks = checks
      @timeout = timeout
    end

    class << self
      # Returns true if the media has a video codec that supports lossless
      # Annex B bitstream extraction (H.264 or H.265).
      #
      # @param media [FFMPEG::Media]
      # @return [Boolean]
      def annexb?(media)
        media.video? && ANNEXB_CODEC_NAMES.include?(media.video_codec_name)
      end
    end

    # Remuxes the media file to the given output path via stream copy.
    # If the initial stream copy fails and the video codec supports Annex B
    # extraction, it falls back to extracting raw streams and re-muxing with
    # a corrected frame rate.
    #
    # @param media [String, Pathname, URI, FFMPEG::Media] The media file to remux.
    # @param output_path [String, Pathname] The output path for the remuxed file.
    # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
    # @return [FFMPEG::Transcoder::Status]
    def process(media, output_path, &)
      media = Media.new(media, load: false) unless media.is_a?(Media)

      status = ffmpeg_copy(media, output_path, &)
      return status if status.success?
      return status unless self.class.annexb?(media)

      Dir.mktmpdir do |tmpdir|
        annexb_extname = media.video_codec_name == 'hevc' ? '.h265' : '.h264'
        annexb_path = File.join(tmpdir, "remux#{annexb_extname}")
        annexb_filter = annexb_filter(media)
        annexb_status = ffmpeg_copy(media, '-map', '0:v:0', *annexb_filter, annexb_path, &)
        return annexb_status unless annexb_status.success?

        mka_path = File.join(tmpdir, 'remux.mka')
        mka_status = ffmpeg_copy(media, '-vn', mka_path, &)
        return mka_status unless mka_status.success?

        video = annexb_status.media.first
        audio = mka_status.media.first
        frame_rate = detect_frame_rate(video, audio)

        status = ffmpeg_copy(
          [video, audio, media],
          '-map', '0:v',
          '-map', '1:a',
          '-map_metadata', '2',
          output_path,
          inargs: %W[-r #{frame_rate}],
          &
        )
        return status unless status.success?
        return status unless FFMPEG.exiftool_binary

        FFMPEG.exiftool_capture3(
          '-overwrite_original',
          "-rotation=#{media.rotation}",
          output_path
        ).tap do |_, stderr, exiftool_status|
          next if exiftool_status.success?

          status.warn!("ExifTool exited with non-zero status: #{exiftool_status.exitstatus}\n#{stderr.strip}")
        end

        status
      end
    end

    # Remuxes the media file to the given output path via stream copy,
    # raising an error if the remux fails.
    #
    # @param media [String, Pathname, URI, FFMPEG::Media] The media file to remux.
    # @param output_path [String, Pathname] The output path for the remuxed file.
    # @yield [report] Reports from the ffmpeg command (see FFMPEG::Reporters).
    # @return [FFMPEG::Transcoder::Status]
    def process!(media, output_path, &)
      process(media, output_path, &).assert!
    end

    protected

    def ffmpeg_copy(media, *args, inargs: [], &)
      media = [media] unless media.is_a?(Array)

      FFMPEG.ffmpeg_execute(
        *inargs.map(&:to_s),
        *media.map { ['-i', _1.path.to_s] }.flatten,
        '-c',
        'copy',
        *args.map(&:to_s),
        timeout: @timeout,
        status: Transcoder::Status.new([args.last], checks: @checks),
        &
      )
    end

    def annexb_filter(media)
      ['-bsf:v', "#{media.video_codec_name}_mp4toannexb"]
    end

    def detect_frame_rate(video, audio)
      stdout, = FFMPEG.ffprobe_capture3(
        '-v', 'quiet',
        '-count_packets',
        '-select_streams', 'v:0',
        '-show_entries', 'stream=nb_read_packets',
        '-of', 'csv=p=0',
        video.path
      )
      frame_count = stdout.strip.to_i

      stdout, = FFMPEG.ffprobe_capture3(
        '-v', 'quiet',
        '-show_entries', 'format=duration',
        '-of', 'csv=p=0',
        audio.path
      )
      duration = stdout.strip.to_f

      (frame_count.to_f / duration).round
    end
  end
end
