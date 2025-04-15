# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Media do
    let(:load) { true }
    let(:autoload) { true }
    let(:path) { fixture_media_file('landscape@4k60.mp4') }

    subject { described_class.new(path, load:, autoload:) }

    before(:all) { start_web_server }
    after(:all) { stop_web_server }

    describe '#initialize' do
      context 'when load is set to false' do
        let(:load) { false }

        it 'does not load the media' do
          expect_any_instance_of(described_class).not_to receive(:load!)
          expect(subject.path).to eq(path)
        end

        it 'autoloads the media on demand' do
          expect_any_instance_of(described_class).to receive(:load!).and_call_original
          expect(subject.valid?).to be(true)
          expect(subject.video_streams?).to be(true)
        end

        context 'and autoload is set to false' do
          let(:autoload) { false }

          it 'does not autoload the media on demand' do
            expect_any_instance_of(described_class).not_to receive(:load!)
            expect { subject.valid? }.to raise_error(RuntimeError, /media not loaded/i)
          end
        end
      end
    end

    describe '#load!' do
      let(:load) { false }

      it 'loads the media once' do
        expect(FFMPEG).to receive(:ffprobe_capture3).once.and_call_original
        subject.load!
        subject.load!
      end

      context 'when the file does not exist' do
        let(:path) { fixture_media_file('missing.mp4') }

        it 'raises an error' do
          expect { subject.load! }.to raise_error(described_class::LoadError, /\bno such file or directory\b/i)
        end
      end

      context 'when the remote file does not exist' do
        let(:path) { fixture_media_file('missing.mp4', remote: true) }

        it 'raises an error' do
          expect { subject.load! }.to raise_error(described_class::LoadError, /\b404 not found\b/i)
        end
      end

      context 'when the remote file was moved' do
        let(:path) { fixture_media_file('moved', 'landscape@4k60.mp4', remote: true) }

        it 'does not raise an error' do
          expect { subject.load! }.not_to raise_error
          expect(subject.valid?).to be(true)
        end
      end

      context 'when the ffprobe output contains' do
        context 'an error' do
          let(:path) { fixture_media_file('broken.mp4') }

          it 'raises an error' do
            expect { subject.load! }.to raise_error(described_class::LoadError, /\binvalid data found\b/i)
          end
        end

        context 'bad JSON' do
          let(:stdout) { read_fixture_file('outputs', 'ffprobe-bad-json.txt') }

          before { allow(FFMPEG).to receive(:ffprobe_capture3).and_return([stdout, '', nil]) }

          it 'raises an error' do
            expect { subject.load! }.to raise_error(described_class::LoadError, /\bunexpected (character|token)\b/i)
          end
        end

        context 'ISO-8859-1 byte sequences' do
          let(:stdout) { read_fixture_file('outputs', 'ffprobe-iso8859.txt') }

          before { allow(FFMPEG).to receive(:ffprobe_capture3).and_return([stdout, '', nil]) }

          it 'does not raise an error' do
            expect(subject.load!).to be(true)
          end
        end
      end
    end

    describe '#remote?' do
      context 'when the media is a remote file' do
        let(:path) { fixture_media_file('landscape@4k60.mp4', remote: true) }

        it 'returns true' do
          expect(subject.remote?).to be(true)
        end
      end

      context 'when the media is a local file' do
        it 'returns false' do
          expect(subject.remote?).to be(false)
        end
      end
    end

    describe '#local?' do
      context 'when the media is a remote file' do
        let(:path) { fixture_media_file('landscape@4k60.mp4', remote: true) }

        it 'returns false' do
          expect(subject.local?).to be(false)
        end
      end

      context 'when the media is a local file' do
        it 'returns true' do
          expect(subject.local?).to be(true)
        end
      end
    end

    describe '#valid?' do
      context 'when the media contains' do
        context 'supported and unsupported streams' do
          let(:stdout) { read_fixture_file('outputs', 'ffprobe-unsupported-audio-stdout.txt') }
          let(:stderr) { read_fixture_file('outputs', 'ffprobe-unsupported-audio-stderr.txt') }

          before { expect(FFMPEG).to receive(:ffprobe_capture3).and_return([stdout, stderr, nil]) }

          it 'returns true' do
            expect(subject.valid?).to be(true)
          end
        end

        context 'only unsupported streams' do
          let(:stdout) { read_fixture_file('outputs', 'ffprobe-unsupported-audio-and-video-stdout.txt') }
          let(:stderr) { read_fixture_file('outputs', 'ffprobe-unsupported-audio-and-video-stderr.txt') }

          before { expect(FFMPEG).to receive(:ffprobe_capture3).and_return([stdout, stderr, nil]) }

          it 'returns false' do
            expect(subject.valid?).to be(false)
          end
        end

        context 'only supported streams' do
          it 'returns true' do
            expect(subject.valid?).to be(true)
          end
        end
      end
    end

    describe '#video_streams' do
      context 'when the media has video streams' do
        it 'returns the video streams' do
          expect(subject.video_streams.length).to be >= 1
          expect(subject.video_streams).to all(be_a(FFMPEG::Stream))
          expect(subject.video_streams.select(&:video?)).to eq(subject.video_streams)
        end
      end

      context 'when the media does not have video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns an empty array' do
          expect(subject.video_streams).to eq([])
        end
      end
    end

    describe '#video_streams?' do
      context 'when the media has video streams' do
        it 'returns true' do
          expect(subject.video_streams?).to be(true)
        end
      end

      context 'when the media does not have video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns false' do
          expect(subject.video_streams?).to be(false)
        end
      end
    end

    describe '#video?' do
      context 'when the media has a moving video stream' do
        it 'returns true' do
          expect(subject.video?).to be(true)
        end
      end

      context 'when the media has moving and still video streams' do
        let(:path) { fixture_media_file('attached-pic.mov') }

        it 'returns true' do
          expect(subject.video?).to be(true)
        end
      end

      context 'when the media only has still video streams' do
        let(:path) { fixture_media_file('napoleon.mp3') }

        it 'returns false' do
          expect(subject.video?).to be(false)
        end
      end

      context 'when the media has no video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns false' do
          expect(subject.video?).to be(false)
        end
      end
    end

    describe '#default_video_stream' do
      context 'when the media has a default video stream' do
        it 'returns the default video stream' do
          expect(subject.default_video_stream).to be_a(FFMPEG::Stream)
          expect(subject.default_video_stream.video?).to be(true)
          expect(subject.default_video_stream.default?).to be(true)
        end
      end

      context 'when the media does not have video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns nil' do
          expect(subject.default_video_stream).to be(nil)
        end
      end
    end

    describe '#rotated?' do
      context 'when the default video stream is not rotated' do
        it 'returns false' do
          expect(subject.rotated?).to be(false)
        end
      end

      context 'when the default video stream is rotated' do
        let(:path) { fixture_media_file('rotated@90.mov') }

        it 'returns true' do
          expect(subject.rotated?).to be(true)
        end
      end

      context 'when the default video stream is fully rotated' do
        let(:path) { fixture_media_file('rotated@180.mov') }

        it 'returns false' do
          expect(subject.rotated?).to be(false)
        end
      end

      context 'when the media has no video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns false' do
          expect(subject.rotated?).to be(false)
        end
      end
    end

    describe '#portrait?' do
      context 'when the default video stream is not portrait' do
        it 'returns false' do
          expect(subject.portrait?).to be(false)
        end
      end

      context 'when the default video stream is portrait' do
        let(:path) { fixture_media_file('portrait@4k60.mp4') }

        it 'returns true' do
          expect(subject.portrait?).to be(true)
        end
      end

      context 'when the media has no video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns false' do
          expect(subject.portrait?).to be(false)
        end
      end
    end

    describe '#landscape?' do
      context 'when the default video stream is landscape' do
        it 'returns true' do
          expect(subject.landscape?).to be(true)
        end
      end

      context 'when the default video stream is not landscape' do
        let(:path) { fixture_media_file('portrait@4k60.mp4') }

        it 'returns false' do
          expect(subject.landscape?).to be(false)
        end
      end

      context 'when the media has no video streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns false' do
          expect(subject.landscape?).to be(false)
        end
      end
    end

    describe '#width' do
      context 'when the default video stream is not rotated' do
        it 'returns its width' do
          expect(subject.width).to be(3840)
        end
      end

      context 'when the default video stream is rotated' do
        let(:path) { fixture_media_file('portrait@4k60.mp4') }

        it 'returns its height' do
          expect(subject.width).to be(2160)
        end
      end
    end

    describe '#raw_width' do
      let(:path) { fixture_media_file('portrait@4k60.mp4') }

      it 'returns the width of the default video stream' do
        expect(subject.raw_width).to be(3840)
      end
    end

    describe '#height' do
      context 'when the default video stream is not rotated' do
        it 'returns its height' do
          expect(subject.height).to be(2160)
        end
      end

      context 'when the default video stream is rotated' do
        let(:path) { fixture_media_file('portrait@4k60.mp4') }

        it 'returns its width' do
          expect(subject.height).to be(3840)
        end
      end
    end

    describe '#raw_height' do
      let(:path) { fixture_media_file('portrait@4k60.mp4') }

      it 'returns the height of the default video stream' do
        expect(subject.raw_height).to be(2160)
      end
    end

    describe '#rotation' do
      context 'when the default video stream is not rotated' do
        it 'returns nil' do
          expect(subject.rotation).to be(nil)
        end
      end

      [90, 180, 270].each do |rotation|
        context "when the default video stream is rotated at #{rotation}" do
          let(:path) { fixture_media_file("rotated@#{rotation}.mov") }

          it "returns #{rotation}" do
            expect(subject.rotation).to be(rotation)
          end
        end
      end
    end

    describe '#resolution' do
      context 'when the default video stream is not rotated' do
        it 'returns the correct resolution' do
          expect(subject.resolution).to eq('3840x2160')
        end
      end

      context 'when the default video stream is rotated' do
        let(:path) { fixture_media_file('portrait@4k60.mp4') }

        it 'returns the correct resolution' do
          expect(subject.resolution).to eq('2160x3840')
        end
      end
    end

    describe '#display_aspect_ratio' do
      context 'when the default video stream is not rotated' do
        it 'returns the aspect ratio of the default video stream' do
          expect(subject.display_aspect_ratio).to eq(Rational(16, 9))
        end
      end

      context 'when the default video stream is rotated' do
        let(:path) { fixture_media_file('portrait@4k60.mp4') }

        it 'returns the inverted aspect ratio of the default video stream' do
          expect(subject.display_aspect_ratio).to eq(Rational(9, 16))
        end
      end
    end

    {
      raw_sample_aspect_ratio: '1:1',
      sample_aspect_ratio: Rational(1),
      raw_display_aspect_ratio: '16:9',
      display_aspect_ratio: Rational(16, 9),
      pixel_format: 'yuvj420p',
      color_range: 'pc',
      color_space: 'bt709',
      color_primaries: 'bt709',
      color_transfer: 'bt709',
      frame_rate: Rational(60 / 1),
      frames: 213,
      video_index: 0,
      video_mapping_index: 0,
      video_mapping_id: 'v:0',
      video_profile: 'High',
      video_codec_name: 'h264',
      video_bit_rate: 41_401_600,
      # rubocop:disable Layout/LineLength
      video_overview:
        %r{h264 \(High\) \(avc1 / 0x31637661\), yuvj420p\(pc, bt709/bt709/bt709, (progressive|unknown)\), 3840x2160 \[SAR 1:1 DAR 16:9\]},
      # rubocop:enable Layout/LineLength
      video_tags: {
        encoder: 'Lavc61.19.100 libx264',
        handler_name: 'VideoHandle',
        language: 'eng',
        vendor_id: '[0][0][0][0]'
      }
    }.each do |method, value|
      describe "##{method}" do
        it "returns the #{method.to_s.gsub(/^video_/, '').gsub('_', ' ')} of the default video stream" do
          if value.is_a?(Regexp)
            expect(subject.public_send(method)).to match(value)
          else
            expect(subject.public_send(method)).to eq(value)
          end
        end
      end
    end

    describe '#audio_streams' do
      context 'when the media has audio streams' do
        let(:path) { fixture_media_file('widescreen-multi-audio.mp4') }

        it 'returns the audio streams' do
          expect(subject.audio_streams.length).to be >= 1
          expect(subject.audio_streams).to all(be_a(FFMPEG::Stream))
          expect(subject.audio_streams.select(&:audio?)).to eq(subject.audio_streams)
        end
      end

      context 'when the media does not have audio streams' do
        let(:path) { fixture_media_file('widescreen-no-audio.mp4') }

        it 'returns an empty array' do
          expect(subject.audio_streams).to eq([])
        end
      end
    end

    describe '#audio_streams?' do
      context 'when the media has audio streams' do
        it 'returns true' do
          expect(subject.audio_streams?).to be(true)
        end
      end

      context 'when the media does not have audio streams' do
        let(:path) { fixture_media_file('widescreen-no-audio.mp4') }

        it 'returns false' do
          expect(subject.audio_streams?).to be(false)
        end
      end
    end

    describe '#audio?' do
      context 'when the media only has audio streams' do
        let(:path) { fixture_media_file('hello.wav') }

        it 'returns true' do
          expect(subject.audio?).to be(true)
        end
      end

      context 'when the media only has audio streams and still video streams' do
        let(:path) { fixture_media_file('napoleon.mp3') }

        it 'returns true' do
          expect(subject.audio?).to be(true)
        end
      end

      context 'when the media has audio and moving video streams' do
        it 'returns false' do
          expect(subject.audio?).to be(false)
        end
      end

      context 'when the media has no audio streams' do
        let(:path) { fixture_media_file('widescreen-no-audio.mp4') }

        it 'returns false' do
          expect(subject.audio?).to be(false)
        end
      end
    end

    describe '#silent?' do
      context 'when the media has an audio stream' do
        it 'returns false' do
          expect(subject.silent?).to be(false)
        end
      end

      context 'when the media has no audio streams' do
        let(:path) { fixture_media_file('widescreen-no-audio.mp4') }

        it 'returns true' do
          expect(subject.silent?).to be(true)
        end
      end
    end

    describe '#default_audio_stream' do
      context 'when the media has a default audio stream' do
        let(:path) { fixture_media_file('widescreen-multi-audio.mp4') }

        it 'returns the default audio stream' do
          expect(subject.default_audio_stream).to be_a(FFMPEG::Stream)
          expect(subject.default_audio_stream.audio?).to be(true)
          expect(subject.default_audio_stream.default?).to be(true)
        end
      end

      context 'when the media does not have audio streams' do
        let(:path) { fixture_media_file('widescreen-no-audio.mp4') }

        it 'returns nil' do
          expect(subject.default_audio_stream).to be(nil)
        end
      end
    end

    {
      audio_index: 1,
      audio_mapping_index: 0,
      audio_mapping_id: 'a:0',
      audio_codec_name: 'aac',
      audio_bit_rate: 192_028,
      audio_overview: 'aac (mp4a / 0x6134706d), 48000 Hz, stereo, fltp, 192028 bit/s',
      audio_tags: {
        handler_name: 'SoundHandle',
        language: 'eng',
        vendor_id: '[0][0][0][0]'
      }
    }.each do |method, value|
      describe "##{method}" do
        it "returns the #{method.to_s.gsub(/^audio_/, '').gsub('_', ' ')} of the default audio stream" do
          expect(subject.public_send(method)).to eq(value)
        end
      end
    end

    describe '#ffmpeg_execute' do
      it 'executes a ffmpeg command with the media as input' do
        reports = []
        block = ->(report) { reports << report }
        args = %w[-af silencedetect=d=0.5 -f null -]
        reporters = [FFMPEG::Reporters::Silence]

        expect(FFMPEG).to receive(:ffmpeg_execute).and_call_original

        status = subject.ffmpeg_execute(*args, reporters:, &block)
        expect(status).to be_a(FFMPEG::Status)
        expect(status.exitstatus).to be(0)

        expect(reports.length).to be >= 1
        expect(reports).to all(be_a(FFMPEG::Reporters::Output))
        expect(reports.select do |report|
          report.is_a?(FFMPEG::Reporters::Silence)
        end.length).to be >= 1
      end
    end

    describe '#ffmpeg_execute!' do
      it 'calls assert! on the result of ffmpeg_execute' do
        inargs = [SecureRandom.hex]
        args = [SecureRandom.hex]
        status = instance_double(Status)
        reporters = [SecureRandom.hex]
        timeout = rand(999)
        block = proc {}

        expect(status).to receive(:assert!).and_return(status)
        expect(subject).to receive(:ffmpeg_execute).with(*args, inargs:, status:, reporters:, timeout:,
                                                         &block).and_return(status)
        expect(subject.ffmpeg_execute!(*args, inargs:, status:, reporters:, timeout:, &block)).to be(status)
      end
    end
  end
end
