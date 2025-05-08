# frozen_string_literal: true

require_relative 'composable'

module FFMPEG
  class CommandArgs
    # The ColorSpaceInjection composable contains logic for injecting
    # color space metadata into video streams by taking a wild guess at the
    # color space (uses bt709 for H.264 and HEVC).
    # This composable is best used as an input argument composer.
    # See https://trac.ffmpeg.org/ticket/11020 for more information.
    module ColorSpaceInjection
      include FFMPEG::CommandArgs::Composable

      compose do
        next unless media.video_streams?
        next unless %w[h264 hevc].include?(media.video_codec_name)
        next unless media.color_space == 'reserved'

        bitstream_filter FFMPEG::Filter.new(
          :video,
          "#{media.video_codec_name}_metadata",
          colour_primaries: 1,
          transfer_characteristics: 1,
          matrix_coefficients: 1
        )
      end
    end
  end
end
