# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  module Reporters
    describe Silence do
      subject do
        described_class.new(
          '[silencedetect @ 0x7f8c6c000000] silence_start: 1.69 silence_end: 2.42 silence_duration: 0.73'
        )
      end

      describe '.match?' do
        context 'when the line starts with a silence report' do
          it 'returns true' do
            expect(Silence.match?('[silencedetect @ 0x7f8c6c000000]')).to be(true)
          end
        end

        context 'when the line does not start with a silence report' do
          it 'returns false' do
            expect(Silence.match?('size=1')).to be(false)
          end
        end
      end

      describe '#filter_id' do
        it 'returns the ID of the filter' do
          expect(subject.filter_id).to eq('0x7f8c6c000000')
        end
      end

      describe '#start' do
        it 'returns the start time of the silence' do
          expect(subject.start).to eq(1.69)
        end
      end

      describe '#end' do
        it 'returns the end time of the silence' do
          expect(subject.end).to eq(2.42)
        end
      end

      describe '#duration' do
        it 'returns the duration of the silence' do
          expect(subject.duration).to eq(0.73)
        end
      end
    end
  end
end
