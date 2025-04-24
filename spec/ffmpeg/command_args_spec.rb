# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe CommandArgs do
    describe '#frame_rate' do
      context 'when the target value is nil' do
        it 'does not set the frame rate' do
          media = instance_double(Media, frame_rate: 30)
          args = CommandArgs.compose(media) { frame_rate nil }
          expect(args.to_a).to eq(%w[])
        end
      end

      context 'when the media frame rate is nil' do
        it 'sets the frame rate to the target value' do
          media = instance_double(Media, frame_rate: nil)
          args = CommandArgs.compose(media) { frame_rate 60 }
          expect(args.to_a).to eq(%w[-r 60])
        end
      end

      context 'when the media frame rate is higher than the target value' do
        it 'sets the frame rate to the target value' do
          media = instance_double(Media, frame_rate: 60)
          args = CommandArgs.compose(media) { frame_rate 30 }
          expect(args.to_a).to eq(%w[-r 30])
        end
      end

      context 'when the media frame rate is lower than the target value' do
        it 'sets the frame rate to the closest standard value' do
          {
            0 => 12,
            21 => 24,
            26 => 25,
            29.94 => 30,
            480 => 240
          }.each do |media_frame_rate, expected_value|
            media = instance_double(Media, frame_rate: media_frame_rate)
            args = CommandArgs.compose(media) { frame_rate 1000 }
            expect(args.to_a).to eq(%W[-r #{expected_value}])
          end
        end
      end
    end

    describe '#video_bit_rate' do
      context 'when the media video bit rate is lower than the target value' do
        it 'sets the video bit rate to the media video bit rate' do
          media = instance_double(Media, video_bit_rate: 128_000)
          args = CommandArgs.compose(media) { video_bit_rate '256k' }
          expect(args.to_a).to eq(%w[-b:v 128k])
        end
      end

      context 'when the media video bit rate is higher than the target value' do
        it 'sets the video bit rate to the target value' do
          media = instance_double(Media, video_bit_rate: 256_000)
          args = CommandArgs.compose(media) { video_bit_rate '128k' }
          expect(args.to_a).to eq(%w[-b:v 128k])
        end
      end

      context 'when the target value is nil' do
        it 'does not set the video bit rate' do
          media = instance_double(Media, video_bit_rate: 128_000)
          args = CommandArgs.compose(media) { video_bit_rate nil }
          expect(args.to_a).to eq(%w[])
        end
      end
    end

    describe '#min_video_bit_rate' do
      context 'when the media video bit rate is lower than the target value' do
        it 'sets the video bit rate to the media video bit rate' do
          media = instance_double(Media, video_bit_rate: 128_000)
          args = CommandArgs.compose(media) { min_video_bit_rate '256k' }
          expect(args.to_a).to eq(%w[-minrate 128k])
        end
      end

      context 'when the media video bit rate is higher than the target value' do
        it 'sets the video bit rate to the target value' do
          media = instance_double(Media, video_bit_rate: 256_000)
          args = CommandArgs.compose(media) { min_video_bit_rate '128k' }
          expect(args.to_a).to eq(%w[-minrate 128k])
        end
      end

      context 'when the target value is nil' do
        it 'does not set the video bit rate' do
          media = instance_double(Media, video_bit_rate: 128_000)
          args = CommandArgs.compose(media) { min_video_bit_rate nil }
          expect(args.to_a).to eq(%w[])
        end
      end
    end

    describe '#max_video_bit_rate' do
      context 'when the media video bit rate is lower than the target value' do
        it 'sets the video bit rate to the media video bit rate' do
          media = instance_double(Media, video_bit_rate: 128_000)
          args = CommandArgs.compose(media) { max_video_bit_rate '256k' }
          expect(args.to_a).to eq(%w[-maxrate 128k])
        end
      end

      context 'when the media video bit rate is higher than the target value' do
        it 'sets the video bit rate to the target value' do
          media = instance_double(Media, video_bit_rate: 256_000)
          args = CommandArgs.compose(media) { max_video_bit_rate '128k' }
          expect(args.to_a).to eq(%w[-maxrate 128k])
        end
      end

      context 'when the target value is nil' do
        it 'does not set the video bit rate' do
          media = instance_double(Media, video_bit_rate: 128_000)
          args = CommandArgs.compose(media) { max_video_bit_rate nil }
          expect(args.to_a).to eq(%w[])
        end
      end
    end

    describe '#audio_bit_rate' do
      context 'when the media audio bit rate is lower than the target value' do
        it 'sets the audio bit rate to the media audio bit rate' do
          media = instance_double(Media, audio_bit_rate: 128_000)
          args = CommandArgs.compose(media) { audio_bit_rate '256k' }
          expect(args.to_a).to eq(%w[-b:a 128k])
        end
      end

      context 'when the media audio bit rate is higher than the target value' do
        it 'sets the audio bit rate to the target value' do
          media = instance_double(Media, audio_bit_rate: 256_000)
          args = CommandArgs.compose(media) { audio_bit_rate '128k' }
          expect(args.to_a).to eq(%w[-b:a 128k])
        end
      end

      context 'when the target value is nil' do
        it 'does not set the audio bit rate' do
          media = instance_double(Media, audio_bit_rate: 128_000)
          args = CommandArgs.compose(media) { audio_bit_rate nil }
          expect(args.to_a).to eq(%w[])
        end
      end
    end
  end
end
