# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  class CommandArgs
    describe ColorSpaceInjection do
      let(:media) { instance_double(FFMPEG::Media) }

      subject(:args) do
        CommandArgs.compose(media) do
          use ColorSpaceInjection
        end.to_a
      end

      context 'when the media has no video streams' do
        before { allow(media).to receive(:video_streams?).and_return(false) }

        it 'does not apply color space injection arguments' do
          expect(args).to be_empty
        end
      end

      context 'when the media video codec is not H.264 or HEVC' do
        before do
          allow(media).to receive(:video_streams?).and_return(true)
          allow(media).to receive(:video_codec_name).and_return('vp9')
        end

        it 'does not apply color space injection arguments' do
          expect(args).to be_empty
        end
      end

      context 'when the media color space is not reserved' do
        before do
          allow(media).to receive(:video_streams?).and_return(true)
          allow(media).to receive(:video_codec_name).and_return('h264')
          allow(media).to receive(:color_space).and_return('bt709')
        end

        it 'does not apply color space injection arguments' do
          expect(args).to be_empty
        end
      end

      context 'when the media meets all conditions for color space injection' do
        before do
          allow(media).to receive(:video_streams?).and_return(true)
          allow(media).to receive(:video_codec_name).and_return('h264')
          allow(media).to receive(:color_space).and_return('reserved')
        end

        it 'applies color space injection arguments' do
          expect(args).to eq(
            %w[
              -bsf:v
              h264_metadata=colour_primaries=1:transfer_characteristics=1:matrix_coefficients=1
            ]
          )
        end
      end
    end
  end
end
