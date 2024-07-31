# frozen_string_literal: true

require_relative '../spec_helper'

module FFMPEG
  describe Stream do
    let(:metadata) { { index: 1 } }
    let(:stderr) { '' }
    subject { Stream.new(metadata, stderr) }

    describe '#supported?' do
      context 'when the codec is not supported' do
        let(:stderr) { 'Unsupported codec with id 1 for input stream 1' }

        it 'returns false' do
          expect(subject.supported?).to be(false)
          expect(subject.unsupported?).to be(true)
        end
      end

      context 'when the codec is supported' do
        it 'returns true' do
          expect(subject.supported?).to be(true)
          expect(subject.unsupported?).to be(false)
        end
      end
    end

    describe '#video?' do
      context 'when the codec type is video' do
        let(:metadata) { { codec_type: 'video' } }

        it 'returns true' do
          expect(subject.video?).to be(true)
        end
      end

      context 'when the codec type is not video' do
        let(:metadata) { { codec_type: 'audio' } }

        it 'returns false' do
          expect(subject.video?).to be(false)
        end
      end
    end

    describe '#audio?' do
      context 'when the codec type is audio' do
        let(:metadata) { { codec_type: 'audio' } }

        it 'returns true' do
          expect(subject.audio?).to be(true)
        end
      end

      context 'when the codec type is not audio' do
        let(:metadata) { { codec_type: 'video' } }

        it 'returns false' do
          expect(subject.audio?).to be(false)
        end
      end
    end

    describe '#default?' do
      context 'when marked as default' do
        let(:metadata) { { disposition: { default: 1 } } }

        it 'returns true' do
          expect(subject.default?).to be(true)
        end
      end

      context 'when not marked as default' do
        let(:metadata) { { disposition: { default: 0 } } }

        it 'returns false' do
          expect(subject.default?).to be(false)
        end
      end
    end

    describe '#attached_pic?' do
      context 'when marked as an attached picture' do
        let(:metadata) { { disposition: { attached_pic: 1 } } }

        it 'returns true' do
          expect(subject.attached_pic?).to be(true)
        end
      end

      context 'when not marked as an attached picture' do
        let(:metadata) { { disposition: { attached_pic: 0 } } }

        it 'returns false' do
          expect(subject.attached_pic?).to be(false)
        end
      end
    end

    describe '#width' do
      context 'when the rotation is nil' do
        let(:metadata) { { width: 100, height: 200 } }

        it 'returns the width' do
          expect(subject.width).to eq(100)
        end
      end

      context 'when the rotation is 180' do
        let(:metadata) { { width: 100, height: 200, tags: { rotate: 180 } } }

        it 'returns the width' do
          expect(subject.width).to eq(100)
        end
      end

      context 'when the rotation is not 180' do
        let(:metadata) { { width: 100, height: 200, tags: { rotate: 90 } } }

        it 'returns the height' do
          expect(subject.width).to eq(200)
        end
      end
    end

    describe '#height' do
      context 'when the rotation is nil' do
        let(:metadata) { { width: 100, height: 200 } }

        it 'returns the height' do
          expect(subject.height).to eq(200)
        end
      end

      context 'when the rotation is 180' do
        let(:metadata) { { width: 100, height: 200, tags: { rotate: 180 } } }

        it 'returns the height' do
          expect(subject.height).to eq(200)
        end
      end

      context 'when the rotation is not 180' do
        let(:metadata) { { width: 100, height: 200, tags: { rotate: 90 } } }

        it 'returns the width' do
          expect(subject.height).to eq(100)
        end
      end
    end

    describe '#resolution' do
      context 'when the width and height are nil' do
        let(:metadata) { { width: nil, height: nil } }

        it 'returns nil' do
          expect(subject.resolution).to be_nil
        end
      end

      context 'when the width and height are not nil' do
        let(:metadata) { { width: 100, height: 200 } }

        it 'returns the resolution' do
          expect(subject.resolution).to eq('100x200')
        end
      end
    end

    describe '#calculated_aspect_ratio' do
      context 'when the display_aspect_ratio is nil' do
        let(:metadata) { { width: 100, height: 200 } }

        it 'returns the aspect ratio from the width and height' do
          expect(subject.calculated_aspect_ratio).to eq(Rational(1, 2))
        end
      end

      context 'when the display_aspect_ratio is not nil' do
        let(:metadata) { { width: 100, height: 200, display_aspect_ratio: '16:9' } }

        it 'returns the aspect ratio from the display_aspect_ratio' do
          expect(subject.calculated_aspect_ratio).to eq(Rational(16, 9))
        end

        context 'and the stream is rotated' do
          let(:metadata) { { width: 100, height: 200, display_aspect_ratio: '16:9', tags: { rotate: 90 } } }

          it 'returns the aspect ratio from the display_aspect_ratio' do
            expect(subject.calculated_aspect_ratio).to eq(Rational(9, 16))
          end
        end
      end
    end

    describe '#calculated_pixel_aspect_ratio' do
      context 'when the sample_aspect_ratio is nil' do
        let(:metadata) { { sample_aspect_ratio: nil } }

        it 'returns 1' do
          expect(subject.calculated_pixel_aspect_ratio).to eq(Rational(1))
        end
      end

      context 'when the sample_aspect_ratio is not nil' do
        let(:metadata) { { sample_aspect_ratio: '16:9' } }

        it 'returns the aspect ratio from the sample_aspect_ratio' do
          expect(subject.calculated_pixel_aspect_ratio).to eq(Rational(16, 9))
        end
      end
    end
  end
end
