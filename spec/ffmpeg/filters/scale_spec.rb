# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.scale' do
      it 'returns a scale filter' do
        expect(described_class.scale(width: 640, height: 480).to_s).to eq('scale=w=640:h=480')
      end
    end
  end

  module Filters
    describe Scale do
      describe '.contained' do
        let(:media) { Media.new(fixture_media_file('landscape@4k60.mp4')) }

        it 'raises ArgumentError if media is not an FFMPEG::Media' do
          expect { described_class.contained(nil) }.to raise_error(ArgumentError)
          expect { described_class.contained('media') }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if max_width is not numeric' do
          expect { described_class.contained(media, max_width: 'foo') }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if max_height is not numeric' do
          expect { described_class.contained(media, max_height: 'foo') }.to raise_error(ArgumentError)
        end

        it 'returns nil if max_width and max_height are not specified' do
          expect(described_class.contained(media)).to be_nil
        end

        it 'returns a contained scale filter' do
          expect(described_class.contained(media, max_width: 640).to_s).to eq('scale=w=640:h=-2')
          expect(described_class.contained(media, max_height: 480).to_s).to eq('scale=w=-2:h=480')
          expect(described_class.contained(media, max_width: 640, max_height: 480).to_s).to eq('scale=w=640:h=-2')
        end

        context 'when the media is rotated' do
          let(:media) { Media.new(fixture_media_file('portrait@4k60.mp4')) }

          it 'returns a contained scale filter' do
            expect(described_class.contained(media, max_width: 640).to_s).to eq('scale=w=-2:h=640')
            expect(described_class.contained(media, max_height: 480).to_s).to eq('scale=w=480:h=-2')
            expect(described_class.contained(media, max_width: 640, max_height: 480).to_s).to eq('scale=w=-2:h=640')
          end
        end

        context 'when the aspect ratio is higher than the max_width and max_height' do
          it 'returns a contained scale filter that scales to width' do
            expect(media).to receive(:calculated_aspect_ratio).and_return(2)
            expect(described_class.contained(media, max_width: 640, max_height: 480).to_s).to eq('scale=w=640:h=-2')
          end
        end
      end

      describe '#initialize' do
        it 'raises ArgumentError if width is not numeric or string' do
          expect { described_class.new(width: 1) }.not_to raise_error
          expect { described_class.new(width: 0.01) }.not_to raise_error
          expect { described_class.new(width: '1') }.not_to raise_error
          expect { described_class.new(width: []) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if height is not numeric or string' do
          expect { described_class.new(height: 1) }.not_to raise_error
          expect { described_class.new(height: 0.01) }.not_to raise_error
          expect { described_class.new(height: '1') }.not_to raise_error
          expect { described_class.new(height: []) }.to raise_error(ArgumentError)
        end
      end

      describe '#to_s' do
        it 'returns the filter as a string' do
          filter = described_class.new(zlib: true, width: 640, height: 480, algorithm: 'lanczos')
          expect(filter.to_s).to eq('zscale=w=640:h=480:f=lanczos')

          filter = described_class.new(width: 'iw/2', height: 'ih/2', algorithm: 'lanczos')
          expect(filter.to_s).to eq('scale=w=iw/2:h=ih/2:flags=lanczos')

          filter = described_class.new(width: -2)
          expect(filter.to_s).to eq('scale=w=-2')
        end
      end
    end
  end
end
