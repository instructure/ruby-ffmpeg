# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  module Filters
    describe Grayscale do
      subject { described_class.new }

      describe '#to_s' do
        it 'returns the filter as a string' do
          expect(subject.to_s).to eq('format=gray')
        end
      end

      describe '#to_a' do
        it 'returns the filter as an array' do
          expect(subject.to_a).to eq(['-vf', subject.to_s])
        end
      end
    end
  end
end
