# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe RawCommandArgs do
    subject { RawCommandArgs.new }

    describe '#arg' do
      it 'adds the argument' do
        subject.arg('foo', 'bar')
        expect(subject.to_a).to eq(%w[-foo bar])
      end

      context 'when the value is a hash' do
        it 'adds the argument as kwargs' do
          subject.arg('foo', { bar: 'baz', fizz: 'buzz' })
          expect(subject.to_a).to eq(%w[-foo bar=baz:fizz=buzz])
        end
      end

      context 'when the value is an array' do
        it 'adds the argument as flags' do
          subject.arg('foo', %w[bar baz])
          expect(subject.to_a).to eq(%w[-foo bar|baz])
        end
      end
    end

    describe '#stream_arg' do
      it 'adds the stream argument' do
        subject.stream_arg('foo', 'bar')
        expect(subject.to_a).to eq(%w[-foo bar])
      end

      it 'adds the stream argument with the stream index' do
        subject.stream_arg('foo', 'bar', stream_index: 0)
        expect(subject.to_a).to eq(%w[-foo:0 bar])
      end

      it 'adds the stream argument with the stream type' do
        subject.stream_arg('foo', 'bar', stream_type: 'v')
        expect(subject.to_a).to eq(%w[-foo:v bar])
      end

      it 'adds the stream argument with the stream index and type' do
        subject.stream_arg('foo', 'bar', stream_index: 0, stream_type: 'v')
        expect(subject.to_a).to eq(%w[-foo:v:0 bar])
      end

      it 'adds the stream argument with the stream ID' do
        subject.stream_arg('foo', 'bar', stream_id: '0x101')
        expect(subject.to_a).to eq(%w[-foo:0x101 bar])
      end
    end

    describe '#raw_arg' do
      it 'adds the raw argument' do
        subject.raw_arg('-foo')
        expect(subject.to_a).to eq(%w[-foo])
      end
    end

    describe '#map' do
      it 'adds the map argument' do
        subject.map(0)
        expect(subject.to_a).to eq(%w[-map 0])
      end

      it 'adds the map argument and executes the block' do
        subject.map(0) do
          subject.video_codec_name 'libx264'
        end
        expect(subject.to_a).to eq(%w[-map 0 -c:v libx264])
      end

      context 'when the mapped stream ID is nil' do
        it 'does not execute the block' do
          subject.map(nil) do
            subject.video_codec_name 'libx264'
          end
          expect(subject.to_a).to eq([])
        end
      end
    end

    describe '#filter' do
      it 'adds the correct filter argument' do
        filter = Filters.fps(30)
        subject.filter(filter)
        expect(subject.to_a).to eq(['-filter:v', filter.to_s])
      end
    end

    describe '#filters' do
      it 'adds the correct filter arguments' do
        video_filters = [Filters.fps(30), Filters.grayscale]
        audio_filters = [Filters.silence_detect]
        subject.filters(*video_filters[0..1], *audio_filters, *video_filters[2..])
        expect(subject.to_a).to eq(['-filter:v', Filter.join(*video_filters), '-filter:a', Filter.join(*audio_filters)])
      end
    end

    describe '#bitstream_filter' do
      it 'adds the correct bitstream filter argument' do
        subject.bitstream_filter(Filter.new(:video, 'h264_mp4toannexb'))
        expect(subject.to_a).to eq(%w[-bsf:v h264_mp4toannexb])
      end
    end

    describe '#bitstream_filters' do
      it 'adds the correct bitstream filter arguments' do
        video_filters = [Filter.new(:video, 'h264_mp4toannexb'), Filter.new(:video, 'h264_mp4toannexb')]
        audio_filters = [Filter.new(:audio, 'aac_adtstoasc')]
        subject.bitstream_filters(*video_filters[0..1], *audio_filters, *video_filters[2..])
        expect(subject.to_a).to eq(['-bsf:v', Filter.join(*video_filters), '-bsf:a', Filter.join(*audio_filters)])
      end
    end

    describe '#filter_complex' do
      it 'adds the filter complex argument' do
        subject.filter_complex(Filters.fps(30), 'foo')
        expect(subject.to_a).to eq(%w[-filter_complex fps=30;foo])
      end
    end

    describe '#constant_rate_factor' do
      it 'adds the constant rate factor argument' do
        subject.constant_rate_factor(23)
        expect(subject.to_a).to eq(%w[-crf 23])
      end

      it 'adds the constant rate factor argument with the stream index' do
        subject.constant_rate_factor(23, stream_index: 0)
        expect(subject.to_a).to eq(%w[-crf:0 23])
      end

      it 'adds the constant rate factor argument with the stream type' do
        subject.constant_rate_factor(23, stream_type: 'v')
        expect(subject.to_a).to eq(%w[-crf:v 23])
      end

      it 'adds the constant rate factor argument with the stream index and type' do
        subject.constant_rate_factor(23, stream_index: 0, stream_type: 'v')
        expect(subject.to_a).to eq(%w[-crf:v:0 23])
      end

      it 'adds the constant rate factor argument with the stream ID' do
        subject.constant_rate_factor(23, stream_id: '0x101')
        expect(subject.to_a).to eq(%w[-crf:0x101 23])
      end
    end

    describe '#method_missing' do
      it 'adds the argument' do
        subject.foo('bar')
        expect(subject.to_a).to eq(%w[-foo bar])
      end
    end

    {
      format_name: 'f',
      muxing_flags: 'movflags',
      buffer_size: 'bufsize',
      duration: 't',
      segment_duration: 'seg_duration',
      min_video_bit_rate: 'minrate',
      max_video_bit_rate: 'maxrate',
      frame_rate: 'r',
      pixel_format: 'pix_fmt',
      resolution: 's',
      min_keyframe_interval: 'keyint_min',
      max_keyframe_interval: 'g',
      scene_change_threshold: 'sc_threshold',
      audio_sample_rate: 'ar',
      audio_channels: 'ac',
      audio_sync: 'async'
    }.each do |method, flag|
      describe "##{method}" do
        it "adds the #{method.to_s.gsub('_', ' ')} argument" do
          value = SecureRandom.hex(4)
          subject.public_send(method, value)
          expect(subject.to_a).to eq(["-#{flag}", value])
        end
      end
    end

    {
      aspect_ratio: 'aspect:v',
      video_codec_name: 'c:v',
      video_bit_rate: 'b:v',
      video_preset: 'preset:v',
      video_profile: 'profile:v',
      video_quality: 'q:v',
      audio_codec_name: 'c:a',
      audio_bit_rate: 'b:a',
      audio_preset: 'preset:a',
      audio_profile: 'profile:a',
      audio_quality: 'q:a'
    }.each do |method, flag|
      describe "##{method}" do
        it "adds the #{method.to_s.gsub('_', ' ')} argument" do
          value = SecureRandom.hex(4)
          subject.public_send(method, value)
          expect(subject.to_a).to eq(["-#{flag}", value])
        end

        it "adds the #{method.to_s.gsub('_', ' ')} argument with the stream index" do
          value = SecureRandom.hex(4)
          subject.public_send(method, value, stream_index: 0)
          expect(subject.to_a).to eq(["-#{flag}:0", value])
        end
      end
    end
  end
end
