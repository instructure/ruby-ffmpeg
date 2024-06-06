# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Media do
    subject { described_class.new("#{fixture_path}/movies/awesome_movie.mov") }

    before(:all) { start_web_server }
    after(:all) { stop_web_server }

    describe '#initialize' do
      context 'given a non-existent local file' do
        subject { described_class.new('i_dont_exist') }

        it 'should throw ArgumentError' do
          expect { subject }.to raise_error(Errno::ENOENT, /does not exist/)
        end
      end

      context 'given an unreachable remote file' do
        subject { described_class.new('http://127.0.0.1:8000/notfound/awesome_movie.mov') }

        it 'should throw ArgumentError' do
          expect { subject }.to raise_error(Errno::ENOENT, /404/)
        end
      end

      context 'given a remote file with too many redirects' do
        subject { described_class.new('http://127.0.0.1:8000/moved/awesome_movie.mov') }
        before { FFMPEG.max_http_redirect_attempts = 0 }
        after { FFMPEG.max_http_redirect_attempts = nil }

        it 'should throw HTTPTooManyRedirects' do
          expect { subject }.to raise_error(FFMPEG::HTTPTooManyRedirects)
        end
      end

      context 'given an empty file' do
        subject { described_class.new("#{fixture_path}/movies/empty.flv") }

        it 'should mark the media as invalid' do
          expect(subject.valid?).to be(false)
        end
      end

      context 'given a broken file' do
        subject { described_class.new("#{fixture_path}/movies/broken.mp4") }

        it 'should mark the media as invalid' do
          expect(subject.valid?).to be(false)
        end
      end

      context 'when the ffprobe output' do
        let(:stdout_fixture_file) { nil }
        let(:stderr_fixture_file) { nil }
        let(:stdout) { read_fixture_file("outputs/#{stdout_fixture_file}") }
        let(:stderr) { stderr_fixture_file ? read_fixture_file("outputs/#{stderr_fixture_file}") : '' }

        before { allow(Open3).to receive(:capture3).and_return([stdout, stderr, double(succeeded: true)]) }
        subject { described_class.new(__FILE__) }

        context 'cannot be parsed' do
          let(:stdout_fixture_file) { 'ffprobe_bad_json.txt' }

          it 'should throw RuntimeError' do
            expect { subject }.to raise_error(RuntimeError, /Could not parse output from FFProbe/)
          end
        end

        context 'contains an error' do
          let(:stdout_fixture_file) { 'ffprobe_error.txt' }

          it 'should mark the media as invalid' do
            expect(subject.valid?).to be(false)
            expect(subject.streams).to be_nil
          end
        end

        context 'contains only unsupported streams' do
          let(:stdout_fixture_file) { 'ffprobe_unsupported_audio_and_video_stdout.txt' }
          let(:stderr_fixture_file) { 'ffprobe_unsupported_audio_and_video_stderr.txt' }

          it 'should mark the media as invalid' do
            expect(subject.valid?).to be(false)
            expect(subject.streams).to all(be_unsupported)
          end
        end

        context 'contains some unsupported streams' do
          let(:stdout_fixture_file) { 'ffprobe_unsupported_audio_stdout.txt' }
          let(:stderr_fixture_file) { 'ffprobe_unsupported_audio_stderr.txt' }

          it 'should not mark the media as invalid' do
            expect(subject.valid?).to be(true)
            expect(subject.video.supported?).to be(true)
            expect(subject.audio.first.unsupported?).to be(true)
          end
        end

        context 'contains ISO-8859-1 byte sequences' do
          let(:stdout_fixture_file) { 'ffprobe_iso8859.txt' }

          it 'should not raise an error' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end

    describe '#remote?' do
      it 'should return true if the path is a remote URL' do
        subject = described_class.new('http://127.0.0.1:8000/awesome_movie.mov')
        expect(subject.remote?).to be(true)
        expect(subject.local?).to be(false)
      end

      it 'should return false if the path is a local file' do
        expect(subject.remote?).to be(false)
        expect(subject.local?).to be(true)
      end
    end

    describe '#size' do
      context 'when the path is a remote URL' do
        it 'should return the content-length of the remote file' do
          subject = described_class.new('http://127.0.0.1:8000/moved/awesome_movie.mov')
          expect(subject.size).to eq(455_546)
        end
      end

      context 'when the path is a local file' do
        it 'should return the size of the local file' do
          expect(subject.size).to eq(455_546)
        end
      end
    end

    describe '#video' do
      it 'should return the first video stream' do
        expect(subject.video).to be_a(Stream)
        expect(subject.video.codec_type).to eq('video')
      end
    end

    describe '#video?' do
      it 'should return true if the media has a video stream' do
        expect(subject.video?).to be(true)
      end

      it 'should return false if the media does not have a video stream' do
        subject = described_class.new("#{fixture_path}/sounds/hello.wav")
        expect(subject.video?).to be(false)
      end
    end

    describe '#video_only?' do
      it 'should return true if the media has only a video stream' do
        subject.instance_variable_set(:@audio, [])
        expect(subject.video_only?).to be(true)
      end

      it 'should return false if the media has audio streams' do
        expect(subject.video_only?).to be(false)
      end

      it 'should return false if the media does not have a video stream' do
        subject = described_class.new("#{fixture_path}/sounds/hello.wav")
        expect(subject.video_only?).to be(false)
      end
    end

    %i[
      width
      height
      rotation
      resolution
      display_aspect_ratio
      sample_aspect_ratio
      calculated_aspect_ratio
      calculated_pixel_aspect_ratio
      color_range
      color_space
      frame_rate
      frames
    ].each do |method|
      describe "##{method}" do
        it 'should delegate to the video stream' do
          expect(subject.video).to receive(method).and_return('foo')
          expect(subject.send(method)).to be('foo')
        end

        next unless method == :rotation

        [0, 90, 180, 270].each do |rotation|
          describe "ios_rotate#{rotation}.mov" do
            subject { described_class.new("#{fixture_path}/movies/ios_rotate#{rotation}.mov") }

            it 'should return the correct rotation' do
              expect(subject.rotation).to eq(rotation.zero? ? nil : rotation)
            end
          end
        end
      end
    end

    %i[
      index
      profile
      codec_name
      codec_type
      bitrate
      overview
      tags
    ].each do |method|
      describe "#video_#{method}" do
        it 'should delegate to the video stream' do
          expect(subject.video).to receive(method).and_return('foo')
          expect(subject.send("video_#{method}")).to be('foo')
        end
      end
    end

    describe '#audio' do
      it 'should return the audio streams' do
        expect(subject.audio).to all(be_a(Stream))
        expect(subject.audio.map(&:codec_type)).to all(eq('audio'))
      end
    end

    describe '#audio?' do
      it 'should return true if the media has audio streams' do
        expect(subject.audio?).to be(true)
      end

      it 'should return false if the media does not have audio streams' do
        subject.instance_variable_set(:@audio, [])
        expect(subject.audio?).to be(false)
      end
    end

    describe '#audio_only?' do
      it 'should return true if the media has only audio streams' do
        subject = described_class.new("#{fixture_path}/sounds/hello.wav")
        expect(subject.audio_only?).to be(true)
      end

      it 'should return false if the media has video streams' do
        expect(subject.audio_only?).to be(false)
      end

      it 'should return false if the media does not have audio streams' do
        subject = described_class.new("#{fixture_path}/movies/awesome_movie.mov")
        expect(subject.audio_only?).to be(false)
      end
    end

    %i[
      index
      profile
      codec_name
      codec_type
      bitrate
      channels
      channel_layout
      sample_rate
      overview
      tags
    ].each do |method|
      describe "#audio_#{method}" do
        it 'should delegate to the first audio stream' do
          expect(subject.audio.first).to receive(method).and_return('foo')
          expect(subject.send("audio_#{method}")).to be('foo')
        end
      end
    end

    describe '#transcoder' do
      let(:output_path) { tmp_file(ext: 'mov') }

      it 'returns a transcoder for the media' do
        transcoder = subject.transcoder(output_path, { custom: %w[-vcodec libx264] })
        expect(transcoder).to be_a(Transcoder)
        expect(transcoder.input_path).to eq(subject.path)
        expect(transcoder.output_path).to eq(output_path)
        expect(transcoder.command.join(' ')).to include('-vcodec libx264')
      end
    end

    describe '#transcode' do
      let(:output_path) { tmp_file(ext: 'mov') }
      let(:options) { { custom: %w[-vcodec libx264] } }
      let(:kwargs) { { preserve_aspect_ratio: :width } }

      it 'should run the transcoder' do
        transcoder_double = double(Transcoder)
        expect(Transcoder).to receive(:new)
          .with(subject, output_path, options, **kwargs)
          .and_return(transcoder_double)
        expect(transcoder_double).to receive(:run)

        subject.transcode(output_path, options, **kwargs)
      end
    end

    describe '#screenshot' do
      let(:output_path) { tmp_file(ext: 'jpg') }
      let(:options) { { seek_time: 2, dimensions: '640x480' } }
      let(:kwargs) { { preserve_aspect_ratio: :width } }

      it 'should run the transcoder with screenshot option' do
        transcoder_double = double(Transcoder)
        expect(Transcoder).to receive(:new)
          .with(subject, output_path, options.merge(screenshot: true), **kwargs)
          .and_return(transcoder_double)
        expect(transcoder_double).to receive(:run)

        subject.screenshot(output_path, options, **kwargs)
      end
    end

    describe '#cut' do
      let(:output_path) { tmp_file(ext: 'mov') }
      let(:options) { { custom: %w[-vcodec libx264] } }

      context 'with no input options' do
        it 'should run the transcoder to cut the media' do
          expected_kwargs = { input_options: %w[-to 4] }
          transcoder_double = double(Transcoder)
          expect(Transcoder).to receive(:new)
            .with(subject, output_path, options.merge(seek_time: 2), **expected_kwargs)
            .and_return(transcoder_double)
          expect(transcoder_double).to receive(:run)

          subject.cut(output_path, 2, 4, options)
        end
      end

      context 'with input options as a string array' do
        let(:kwargs) { { input_options: %w[-ss 999] } }

        it 'should run the transcoder to cut the media' do
          expected_kwargs = kwargs.merge({ input_options: kwargs[:input_options] + %w[-to 4] })
          transcoder_double = double(Transcoder)
          expect(Transcoder).to receive(:new)
            .with(subject, output_path, options.merge(seek_time: 2), **expected_kwargs)
            .and_return(transcoder_double)
          expect(transcoder_double).to receive(:run)

          subject.cut(output_path, 2, 4, options, **kwargs)
        end
      end

      context 'with input options as a hash' do
        let(:kwargs) { { input_options: { ss: 999 } } }

        it 'should run the transcoder to cut the media' do
          expected_kwargs = kwargs.merge({ input_options: kwargs[:input_options].merge({ to: 4 }) })
          transcoder_double = double(Transcoder)
          expect(Transcoder).to receive(:new)
            .with(subject, output_path, options.merge(seek_time: 2), **expected_kwargs)
            .and_return(transcoder_double)
          expect(transcoder_double).to receive(:run)

          subject.cut(output_path, 2, 4, options, **kwargs)
        end
      end
    end

    describe '.concat' do
      let(:output_path) { tmp_file(ext: 'mov') }
      let(:segment1_path) { tmp_file(basename: 'segment1', ext: 'mov') }
      let(:segment2_path) { tmp_file(basename: 'segment2', ext: 'mov') }

      it 'should run the transcoder to concatenate the segments' do
        segment1 = subject.cut(segment1_path, 1, 3)
        segment2 = subject.cut(segment2_path, 4, subject.duration)
        result = described_class.concat(output_path, segment1, segment2)
        expect(result).to be_a(Media)
        expect(result.path).to eq(output_path)
        expect(result.duration).to be_within(0.2).of(5.7)
      end
    end
  end
end
