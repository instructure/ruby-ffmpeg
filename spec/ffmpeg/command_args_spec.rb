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

      context 'when the media frame rate is zero' do
        it 'sets the frame rate to the target value' do
          media = instance_double(Media, frame_rate: 0)
          args = CommandArgs.compose(media) { frame_rate 60 }
          expect(args.to_a).to eq(%w[-r 60])
        end
      end

      context 'when the media frame rate is negative' do
        it 'sets the frame rate to the target value' do
          media = instance_double(Media, frame_rate: -1)
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

      context 'when the reported media bitrate is 0' do
        it 'returns the requested bitrate' do
          media = instance_double(Media, video_bit_rate: 0)
          args = CommandArgs.compose(media) { min_video_bit_rate '2M' }
          expect(args.to_a).to eq(%w[-minrate 2000k])
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

    describe '#audio_sample_rate' do
      context 'when the target value is nil' do
        it 'does not set the audio sample rate' do
          media = instance_double(Media, audio_sample_rate: 48_000)
          args = CommandArgs.compose(media) { audio_sample_rate nil }
          expect(args.to_a).to eq(%w[])
        end
      end

      context 'when the media audio sample rate is nil' do
        it 'sets the audio sample rate to the target value' do
          media = instance_double(Media, audio_sample_rate: nil)
          args = CommandArgs.compose(media) { audio_sample_rate 48_000 }
          expect(args.to_a).to eq(%w[-ar 48000])
        end
      end

      context 'when the media audio sample rate is zero' do
        it 'sets the audio sample rate to the target value' do
          media = instance_double(Media, audio_sample_rate: 0)
          args = CommandArgs.compose(media) { audio_sample_rate 48_000 }
          expect(args.to_a).to eq(%w[-ar 48000])
        end
      end

      context 'when the media audio sample rate is negative' do
        it 'sets the audio sample rate to the target value' do
          media = instance_double(Media, audio_sample_rate: -1)
          args = CommandArgs.compose(media) { audio_sample_rate 48_000 }
          expect(args.to_a).to eq(%w[-ar 48000])
        end
      end

      context 'when the media audio sample rate is higher than the target value' do
        it 'sets the audio sample rate to the target value' do
          media = instance_double(Media, audio_sample_rate: 96_000)
          args = CommandArgs.compose(media) { audio_sample_rate 48_000 }
          expect(args.to_a).to eq(%w[-ar 48000])
        end
      end

      context 'when the media audio sample rate is lower than the target value' do
        it 'sets the audio sample rate to the closest standard value' do
          {
            8000 => 8000,
            10_000 => 11_025,
            12_000 => 11_025,
            20_000 => 22_050,
            44_100 => 44_100,
            45_000 => 44_100,
            47_000 => 48_000,
            90_000 => 88_200,
            100_000 => 96_000
          }.each do |media_sample_rate, expected_value|
            media = instance_double(Media, audio_sample_rate: media_sample_rate)
            args = CommandArgs.compose(media) { audio_sample_rate 192_000 }
            expect(args.to_a).to eq(%W[-ar #{expected_value}])
          end
        end
      end
    end
  end
end
