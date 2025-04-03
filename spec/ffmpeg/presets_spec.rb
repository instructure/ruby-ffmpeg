# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  class PresetTest
    attr_reader :name, :preset, :assert

    def initialize(name:, preset:, assert:)
      @name = name
      @preset = preset
      @assert = assert
    end
  end

  describe Presets do
    let(:media) { Media.new(fixture_media_file('portrait@1080p60.mp4')) }
    let(:output_dir) { Dir.mktmpdir(nil, tmp_dir) }
    let(:output_path) { File.join(output_dir, SecureRandom.hex(4)) }

    [
      PresetTest.new(
        name: 'H.264 360p 30 FPS',
        preset: Presets.h264_360p,
        assert: lambda do |media|
          expect(media.path).to match(/\.mp4\z/)
          expect(media.streams.length).to be(2)
          expect(media.video_streams.length).to be(1)
          expect(media.audio_streams.length).to be(1)
          expect(media.width).to be(360)
          expect(media.height).to be(640)
          expect(media.frame_rate).to eq(Rational(30))
          expect(media.audio_bit_rate).to be_within(15_000).of(128_000)
        end
      ),
      PresetTest.new(
        name: 'AAC 128k',
        preset: Presets.aac_128k,
        assert: lambda do |media|
          expect(media.path).to match(/\.m4a\z/)
          expect(media.major_brand).to eq('M4A')
          expect(media.streams.length).to be(1)
          expect(media.audio_streams.length).to be(1)
          expect(media.audio_bit_rate).to be_within(15_000).of(128_000)
        end
      ),
      PresetTest.new(
        name: 'DASH H.264 4K 30 FPS',
        preset: Presets::DASH.h264_4k,
        assert: lambda do |media|
          expect(media.path).to match(/\.mpd\z/)
          expect(media.streams.length).to be(5)
          expect(media.video_streams.length).to be(4)
          expect(media.audio_streams.length).to be(1)
          expect(media.width).to be(1080)
          expect(media.height).to be(1920)
          expect(media.frame_rate).to eq(Rational(60))
          expect(media.audio_bit_rate).to be_within(15_000).of(128_000)
          expect(media.video_streams.map(&:width)).to eq([1080, 720, 480, 360])
          expect(media.video_streams.map(&:height)).to eq([1920, 1280, 854, 640])
          expect(media.video_streams.map(&:frame_rate)).to eq([Rational(60), Rational(60), Rational(30), Rational(30)])
        end
      ),
      PresetTest.new(
        name: 'DASH AAC 128k',
        preset: Presets::DASH.aac_128k,
        assert: lambda do |media|
          expect(media.path).to match(/\.mpd\z/)
          expect(media.streams.length).to be(1)
          expect(media.audio_streams.length).to be(1)
          expect(media.audio_bit_rate).to be_within(15_000).of(128_000)
        end
      )
    ].each do |test|
      describe test.name do
        it 'transcodes the media to the correct parameters' do
          status = test.preset.transcode(media, output_path)
          expect(status.success?).to be(true)
          instance_exec(status.media.first, &test.assert)
        end
      end
    end
  end
end
