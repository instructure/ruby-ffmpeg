# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Transcoder do
    let(:media) { Media.new("#{fixture_path}/movies/awesome_movie.mov") }

    describe '#initialize' do
      let(:output_path) { tmp_file(ext: 'flv') }

      it 'should accept EncodingOptions as options' do
        expect do
          described_class.new(media, output_path, EncodingOptions.new)
        end.not_to raise_error
      end

      it 'should accept Hash as options' do
        expect do
          described_class.new(media, output_path, { video_codec: 'libx264' })
        end.not_to raise_error
      end

      it 'should accept Array as options' do
        expect do
          described_class.new(media, output_path, %w[-vcodec libx264])
        end.not_to raise_error
      end

      it 'should not accept anything else as options' do
        expect do
          described_class.new(media, output_path, 'string?')
        end.to raise_error(ArgumentError, /Unknown options format/)
      end
    end

    describe '#run' do
      before do
        allow(FFMPEG.logger).to receive(:info)
      end

      let(:input) { media }
      let(:output_ext) { 'mp4' }
      let(:output_path) { tmp_file(ext: output_ext) }
      let(:options) { nil }
      let(:kwargs) { nil }

      subject do
        if options.nil? && kwargs.nil?
          described_class.new(input, output_path)
        elsif options.nil?
          described_class.new(input, output_path, **kwargs)
        elsif kwargs.nil?
          described_class.new(input, output_path, options)
        else
          described_class.new(input, output_path, options, **kwargs)
        end
      end

      context 'when ffmpeg freezes' do
        before do
          Transcoder.timeout = 1
          FFMPEG.ffmpeg_binary = "#{fixture_path}/bin/ffmpeg-hanging"
        end

        after do
          Transcoder.timeout = 30
          FFMPEG.ffmpeg_binary = nil
        end

        it 'should fail when the timeout is exceeded' do
          expect(FFMPEG.logger).to receive(:error)
          expect { subject.run }.to raise_error(FFMPEG::Error, /Process hung/)
        end
      end

      context 'when ffmpeg crashes' do
        let(:input) { 'http://256.256.256.256/bad-address.mp4' }

        it 'should fail with non-zero exit code error' do
          expect(FFMPEG.logger).to receive(:error)
          expect { subject.run }.to raise_error(FFMPEG::Error, /non-zero exit code/)
        end
      end

      context 'with timeout disabled' do
        let(:output_ext) { 'mpg' }
        let(:options) { { target: 'ntsc-vcd' } }

        before { Transcoder.timeout = false }
        after { Transcoder.timeout = 30 }

        it 'should still work with NTSC target' do
          result = subject.run
          expect(result.resolution).to eq('352x240')
        end
      end

      it 'should transcode the input and report progress' do
        reports = []
        subject.run { |progress| reports << progress }

        expect(subject.result).to be_valid
        expect(reports).to include(0.0, 1.0)
        expect(reports.length).to be >= 3
        expect(File.exist?(output_path)).to be_truthy
      end

      context 'with full set of encoding options' do
        let(:options) do
          { video_codec: 'libx264', frame_rate: 10, resolution: '320x240', video_bitrate: 300,
            audio_codec: 'libmp3lame', audio_bitrate: 32, audio_sample_rate: 22_050, audio_channels: 1 }
        end

        it 'should transcode the input' do
          result = subject.run

          expect(result.video_bitrate).to be_within(90_000).of(300_000)
          expect(result.video_codec_name).to match(/h264/)
          expect(result.resolution).to eq('320x240')
          expect(result.frame_rate).to eq(10.0)
          expect(result.audio_bitrate).to be_within(2000).of(32_000)
          expect(result.audio_codec_name).to match(/mp3/)
          expect(result.audio_sample_rate).to eq(22_050)
          expect(result.audio_channels).to eq(1)
          expect(File.exist?(output_path)).to be_truthy
        end
      end

      context 'with audio only' do
        let(:media) { Media.new("#{fixture_path}/sounds/hello.wav") }
        let(:output_ext) { 'mp3' }
        let(:options) { { audio_codec: 'libmp3lame', input_options: %w[-qscale:a 2] } }

        it 'should transcode the input' do
          result = subject.run

          expect(result.video_codec_name).to be_nil
          expect(result.audio_codec_name).to match(/mp3/)
          expect(result.audio_sample_rate).to eq(44_100)
          expect(result.audio_channels).to eq(1)
          expect(File.exist?(output_path)).to be_truthy
        end

        context 'when ffmpeg freezes' do
          before do
            Transcoder.timeout = 1
            FFMPEG.ffmpeg_binary = "#{fixture_path}/bin/ffmpeg-audio-only"
          end

          after do
            Transcoder.timeout = 30
            FFMPEG.ffmpeg_binary = nil
          end

          it 'should fail when the timeout is exceeded' do
            expect { subject.run }.to raise_error(FFMPEG::Error, /Errors: no output file created/)
          end
        end
      end

      context 'with aspect ratio preservation' do
        let(:media) { Media.new("#{fixture_path}/movies/widescreen_movie.mov") }
        let(:options) { { resolution: '320x240' } }
        let(:kwargs) { { preserve_aspect_ratio: :width } }

        context 'set to width' do
          it 'should transcode to the correct resolution' do
            result = subject.run
            expect(result.resolution).to eq('320x180')
          end
        end

        context 'set to height' do
          let(:kwargs) { { preserve_aspect_ratio: :height } }

          it 'should transcode to the correct resolution' do
            result = subject.run
            expect(result.resolution).to eq('426x240')
          end
        end

        it 'should use the specified resolution when if the original aspect ratio is undeterminable' do
          expect(media.video).to receive(:calculated_aspect_ratio).and_return(nil)
          result = subject.run
          expect(result.resolution).to eq('320x240')
        end

        it 'should round to resolutions divisible by 2' do
          expect(media.video).to receive(:calculated_aspect_ratio).at_least(:once).and_return(1.234)
          result = subject.run
          expect(result.resolution).to eq('320x260') # 320 / 1.234 should at first be rounded to 259
        end
      end

      context 'with string array options' do
        let(:options) { %w[-s 300x200 -ac 2] }

        it 'should transcode the input' do
          result = subject.run
          expect(result.resolution).to eq('300x200')
          expect(result.audio_channels).to eq(2)
        end
      end

      context 'with input file that contains single quote' do
        let(:media) { Media.new("#{fixture_path}/movies/awesome'movie.mov") }

        it 'should not fail' do
          expect { subject.run }.not_to raise_error
        end
      end

      context 'with output file that contains single quote' do
        let(:output_path) { "#{tmp_path}/output with 'quote.flv" }

        before { FileUtils.rm_f(output_path) }

        it 'should not fail' do
          expect { subject.run }.not_to raise_error
        end
      end

      context 'with output file that contains ISO-8859-1 characters' do
        let(:output_path) { "#{tmp_path}/saløndethé.flv" }

        before { FileUtils.rm_f(output_path) }

        it 'should not fail' do
          expect { subject.run }.not_to raise_error
        end
      end

      context 'with invalid movie input' do
        let(:media) { Media.new(__FILE__) }

        it 'should fail' do
          expect { subject.run }.to raise_error(FFMPEG::Error, /no output file created/)
        end
      end

      context 'with explicitly set duration' do
        let(:options) { { duration: 2 } }

        it 'should transcode correctly' do
          result = subject.run
          expect(result.duration).to be >= 1.8
          expect(result.duration).to be <= 2.2
        end
      end

      context 'with remote URL as input' do
        let(:media) { Media.new('http://127.0.0.1:8000/awesome_movie.mov') }

        before(:context) { start_web_server }
        after(:context) { stop_web_server }

        it 'should transcode correctly' do
          expect { subject.run }.not_to raise_error
          expect(File.exist?(output_path)).to be_truthy
        end
      end

      context 'with screenshot' do
        let(:output_ext) { 'jpg' }
        let(:options) { { screenshot: true, seek_time: 3 } }

        it 'should produce the correct ffmpeg command' do
          expect(subject.command.join(' ')).to include("-ss 3 -i #{subject.input_path}")
        end

        it 'should transcode to the original resolution by default' do
          result = subject.run
          expect(result.resolution).to eq('640x480')
        end

        context 'and explicitly set resolution' do
          let(:options) { { screenshot: true, seek_time: 3, resolution: '400x200' } }

          it 'should transcode to the specified resolution' do
            result = subject.run
            expect(result.resolution).to eq('400x200')
          end
        end

        context 'and aspect ratio preservation' do
          let(:options) { { screenshot: true, seek_time: 4, resolution: '320x500' } }
          let(:kwargs) { { preserve_aspect_ratio: :width } }

          it 'should transcode to the correct resolution' do
            result = subject.run
            expect(result.resolution).to eq('320x240')
          end
        end

        describe 'for multiple screenshots' do
          let(:output_path) { "#{tmp_path}/screenshots_%d.png" }
          let(:options) { { screenshot: true, seek_time: 4, resolution: '320x500' } }
          let(:kwargs) { { preserve_aspect_ratio: :width } }

          context 'with output file validation' do
            it 'should fail' do
              expect do
                subject.run
              end.to raise_error(FFMPEG::Error, /Failed encoding/)
            end
          end

          context 'without output file validation' do
            let(:kwargs) { { preserve_aspect_ratio: :width, validate: false } }

            it 'should create sequential screenshots' do
              subject.run
              expect(Dir[File.join(tmp_path, 'screenshots_*.png')].count { |file| File.file?(file) }).to eq(1)
            end
          end
        end

        context 'and custom input options' do
          let(:kwargs) { { input_options: %w[-re] } }

          it 'should produce the correct ffmpeg command' do
            expect(subject.command.join(' ')).to include("-re -ss 3 -i #{subject.input_path}")
          end

          context 'that already define -ss' do
            let(:kwargs) { { input_options: %w[-ss 5 -re] } }

            it 'should overwrite the -ss value' do
              expect(subject.command.join(' ')).to include("-ss 3 -re -i #{subject.input_path}")
            end
          end
        end
      end

      context 'with watermarking' do
        let(:options) { { watermark: "#{fixture_path}/images/watermark.png", watermark_filter: { position: 'RT' } } }

        it 'should transcode the input with the watermark' do
          expect { subject.run }.not_to raise_error
        end
      end

      context 'without output file validation' do
        let(:kwargs) { { validate: false } }

        before { allow(subject).to receive(:execute) }

        it 'should not validate the output file' do
          expect(subject).to_not receive(:validate_output_path)
          subject.run
        end

        it 'should not return a Media object' do
          expect(subject).to_not receive(:result)
          expect(subject.run).to eq(nil)
        end
      end

      context 'with custom encoding options' do
        let(:options) { { video_codec: 'libx264', custom: %w[-map 0:0 -map 0:1] } }

        it 'should add the custom encoding options to the command' do
          expect(subject.command.join(' ')).to include('-map 0:0 -map 0:1')
        end
      end

      context 'with custom input options' do
        context 'as a string array' do
          let(:kwargs) { { input_options: %w[-framerate 1/5 -re] } }

          it 'should produce the correct ffmpeg command' do
            expect(subject.command.join(' ')).to include("-framerate 1/5 -re -i #{subject.input_path}")
          end
        end

        context 'as a hash' do
          let(:kwargs) { { input_options: { framerate: '1/5' } } }

          it 'should produce the correct ffmpeg command' do
            expect(subject.command.join(' ')).to include("-framerate 1/5 -i #{subject.input_path}")
          end
        end
      end

      context 'with an image sequence as input' do
        let(:input) { "#{fixture_path}/images/img_%03d.jpeg" }
        let(:kwargs) { { input_options: %w[-framerate 1/5] } }

        it 'should not raise an error' do
          expect { subject.run }.to_not raise_error
        end

        it 'should produce a slideshow' do
          result = subject.run
          expect(result.duration).to eq(25)
        end

        context 'and files where the file extension does not match the file type' do
          let(:input) { "#{fixture_path}/images/wrong_type/img_%03d.tiff" }

          it 'should fail' do
            expect { subject.run }.to raise_error(FFMPEG::Error, /encoded file is invalid/)
          end
        end
      end
    end
  end
end
