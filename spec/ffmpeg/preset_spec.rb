# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Preset do
    describe '#filename' do
      it 'returns the rendered filename' do
        preset = described_class.new(filename: '%<basename>s.mpd')
        expect(preset.filename(basename: 'manifest')).to eq('manifest.mpd')
      end

      context 'when the preset filename is nil' do
        it 'returns nil' do
          preset = described_class.new(filename: nil)
          expect(preset.filename).to be_nil
        end
      end
    end

    describe '#args' do
      it 'returns the command arguments for the media' do
        media = instance_double(Media, frame_rate: 69)
        preset = described_class.new { arg 'r', media.frame_rate }
        expect(preset.args(media)).to eq(%w[-r 69])
      end
    end

    describe '#transcode' do
      it 'transcodes the media to the output path' do
        media = Media.new(fixture_media_file('hello.wav'))

        preset = described_class.new do
          audio_codec_name 'aac'
          audio_bit_rate '128k'
          map media.audio_mapping_id
        end

        status = preset.transcode(media, File.join(tmp_dir, 'hello.aac'))
        expect(status).to be_a(FFMPEG::Transcoder::Status)
        expect(status.success?).to be(true)
        expect(status.paths).to eq([File.join(tmp_dir, 'hello.aac')])
      end
    end
  end
end
