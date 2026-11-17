# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Transcoder do
    describe '#process' do
      let(:media) { Media.new(fixture_media_file('landscape@4k60.mp4')) }

      let(:preset1) do
        Preset.new(filename: '%<basename>s.mp4') do
          video_codec_name 'libx264'
          audio_codec_name 'aac'

          map media.video_mapping_id do
            filter Filters.scale(width: -2, height: 360)
            constant_rate_factor 28
          end

          map media.audio_mapping_id do
            audio_bit_rate '96k'
          end
        end
      end

      let(:preset2) do
        Preset.new(filename: '%<basename>s.aac') do
          audio_codec_name 'aac'

          map media.audio_mapping_id do
            audio_bit_rate '96k'
          end
        end
      end

      let(:retries) { 0 }

      subject do
        described_class.new(presets: [preset1, preset2], retries:) do
          raw_arg '-noautorotate'

          context :retry do
            raw_arg '-xerror'
          end
        end
      end

      it 'transcodes a multimedia file using the specified presets' do
        output_path = File.join(tmp_dir, SecureRandom.hex(4))

        expect(media).to receive(:ffmpeg_execute).and_wrap_original do |method, *args, **kwargs, &block|
          expect(args).to eq(
            %W[
              -c:v libx264 -c:a aac
              -map v:0 -filter:v scale=w=-2:h=360 -crf 28
              -map a:0 -b:a 96k
              #{output_path}.mp4
              -c:a aac
              -map a:0 -b:a 96k
              #{output_path}.aac
            ]
          )

          expect(kwargs).to match(
            hash_including(
              inargs: ['-noautorotate'],
              reporters: nil
            )
          )

          method.call(*args, **kwargs, &block)
        end

        reports = []
        status = subject.process(media, output_path) do |report|
          reports << report
        end

        expect(status).to be_a(Transcoder::Status)
        expect(status.success?).to be(true)
        expect(status.paths).to eq(%W[#{output_path}.mp4 #{output_path}.aac])
        expect(status.media).to all(be_a(Media))
        expect(status.media.first.video?).to be(true)
        expect(status.media.first.height).to eq(360)
        expect(status.media.first.streams.length).to eq(2)
        expect(status.media.first.audio_bit_rate).to be_within(15_000).of(96_000)
        expect(status.media.last.audio?).to be(true)
        expect(status.media.last.streams.length).to eq(1)
        expect(status.media.last.audio_bit_rate).to be_within(15_000).of(96_000)

        expect(reports.length).to be >= 1
        expect(reports).to all(be_a(Reporters::Output))
      end

      context 'when the transcoding process finishes with non-zero exit status' do
        let(:retries) { 1 }

        it 'retries up to the set number of times' do
          output_path = File.join(tmp_dir, SecureRandom.hex(4))

          attempts = 0
          status = double(Transcoder::Status, success?: false)
          expect(media).to receive(:ffmpeg_execute).twice do |*_args, inargs:, **_kwargs|
            attempts += 1

            if attempts == 2
              allow(status).to receive(:success?).and_return(true)
              expect(inargs).to include('-xerror')
            else
              expect(inargs).not_to include('-xerror')
            end

            status
          end

          expect(subject.process(media, output_path)).to be(status)
          expect(attempts).to eq(2)
        end
      end

      it 'can run ffmpeg in a different working directory (chdir)' do
        output_path = File.join(tmp_dir, SecureRandom.hex(4))
        status = double(Transcoder::Status, success?: true)

        expect(FFMPEG::IO).to receive(:popen3)
          .with(any_args, chdir: tmp_dir)
          .and_return(status)

        subject.process(media, output_path, chdir: tmp_dir)
      end
    end

    describe '#process!' do
      it 'calls assert! on the result of process' do
        media = instance_double(Media)
        output_path = File.join(tmp_dir, SecureRandom.hex(4))
        status = instance_double(Transcoder::Status)
        block = proc {}

        expect(status).to receive(:assert!).and_return(status)
        expect(subject).to receive(:process)
          .with(media, output_path, chdir: nil, &block)
          .and_return(status)
        expect(subject.process!(media, output_path, &block)).to eq(status)
      end
    end
  end
end
