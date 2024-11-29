# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.fps' do
      it 'returns a new FPS filter' do
        expect(described_class.split(30).to_s).to eq('split=30')
      end
    end
  end

  module Filters
    describe Split do
      describe '#initialize' do
        it 'raises ArgumentError if output_count is not an integer' do
          expect { described_class.new(30) }.not_to raise_error
          expect { described_class.new(0.01) }.to raise_error(ArgumentError)
          expect { described_class.new('30') }.to raise_error(ArgumentError)
          expect { described_class.new([]) }.to raise_error(ArgumentError)
        end
      end

      describe '#to_s' do
        it 'returns the filter as a string' do
          expect(described_class.new(30).to_s).to eq('split=30')
          expect(described_class.new.to_s).to eq('split')
        end
      end
    end
  end
end
