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

        it 'raises ArgumentError if force_original_aspect_ratio is not string' do
          expect { described_class.new(force_original_aspect_ratio: '1') }.not_to raise_error
          expect { described_class.new(force_original_aspect_ratio: 1) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if flags is not an array' do
          expect { described_class.new(flags: []) }.not_to raise_error
          expect { described_class.new(flags: '1') }.to raise_error(ArgumentError)
        end
      end

      describe '#to_s' do
        it 'returns the filter as a string' do
          filter = described_class.new(width: 640, height: 480, force_original_aspect_ratio: 'decrease')
          expect(filter.to_s).to eq('scale=w=640:h=480:force_original_aspect_ratio=decrease')

          filter = described_class.new(width: 'iw/2', height: 'ih/2', force_original_aspect_ratio: 'increase')
          expect(filter.to_s).to eq('scale=w=iw/2:h=ih/2:force_original_aspect_ratio=increase')

          filter = described_class.new(width: -2)
          expect(filter.to_s).to eq('scale=w=-2')
        end
      end
    end
  end
end
