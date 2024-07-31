# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.grayscale' do
      it 'returns a new grayscale filter' do
        expect(described_class.grayscale.to_s).to eq('format=pix_fmts=gray')
      end
    end
  end

  module Filters
    describe Grayscale do
      describe '#to_s' do
        it 'returns the filter as a string' do
          filter = described_class.new
          expect(filter.to_s).to eq('format=pix_fmts=gray')
        end
      end
    end
  end
end
