# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.fps' do
      it 'returns a new FPS filter' do
        expect(described_class.fps(30).to_s).to eq('fps=30')
      end
    end
  end

  module Filters
    describe FPS do
      describe '#initialize' do
        it 'raises ArgumentError if frame_rate is not numeric' do
          expect { described_class.new(30) }.not_to raise_error
          expect { described_class.new(0.01) }.not_to raise_error
          expect { described_class.new('30') }.to raise_error(ArgumentError)
          expect { described_class.new([]) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
