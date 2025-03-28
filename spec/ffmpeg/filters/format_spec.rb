# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  describe Filters do
    describe '.format' do
      it 'returns a new Format filter' do
        expect(described_class.format(pixel_formats: ['gray']).to_s).to eq('format=pix_fmts=gray')
      end
    end
  end

  module Filters
    describe Format do
      describe '#initialize' do
        it 'raises ArgumentError if none of pixel_formats, color_spaces, or color_ranges are set' do
          expect { described_class.new }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if pixel_formats is not a string or array' do
          expect { described_class.new(pixel_formats: 'gray') }.not_to raise_error
          expect { described_class.new(pixel_formats: ['gray']) }.not_to raise_error
          expect { described_class.new(pixel_formats: 0) }.to raise_error(ArgumentError)
          expect { described_class.new(pixel_formats: {}) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if color_spaces is not a string or array' do
          expect { described_class.new(color_spaces: 'bt709') }.not_to raise_error
          expect { described_class.new(color_spaces: ['bt709']) }.not_to raise_error
          expect { described_class.new(color_spaces: 0) }.to raise_error(ArgumentError)
          expect { described_class.new(color_spaces: {}) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError if color_ranges is not a string or array' do
          expect { described_class.new(color_ranges: 'tv') }.not_to raise_error
          expect { described_class.new(color_ranges: ['tv']) }.not_to raise_error
          expect { described_class.new(color_ranges: 0) }.to raise_error(ArgumentError)
          expect { described_class.new(color_ranges: {}) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
