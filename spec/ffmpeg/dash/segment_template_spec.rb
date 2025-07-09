# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::SegmentTemplate do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }
  let(:video_segment_template) do
    manifest.adaptation_sets.find { _1.content_type == 'video' }.representations.first.segment_template
  end
  let(:audio_segment_template) do
    manifest.adaptation_sets.find { _1.content_type == 'audio' }.representations.first.segment_template
  end

  describe '#timescale' do
    it 'returns the timescale' do
      expect(video_segment_template.timescale).to eq(90_000)
      expect(audio_segment_template.timescale).to eq(48_000)
    end
  end

  describe '#initialization' do
    it 'returns the initialization' do
      expect(video_segment_template.initialization).to eq('init-stream$RepresentationID$.m4s')
      expect(audio_segment_template.initialization).to eq('init-stream$RepresentationID$.m4s')
    end
  end

  describe '#media' do
    it 'returns the media' do
      expect(video_segment_template.media).to eq('chunk-stream$RepresentationID$-$Number$.m4s')
      expect(audio_segment_template.media).to eq('chunk-stream$RepresentationID$-$Number$.m4s')
    end
  end

  describe '#start_number' do
    it 'returns the start number' do
      expect(video_segment_template.start_number).to eq(1)
      expect(audio_segment_template.start_number).to eq(1)
    end
  end

  describe '#segment_timeline' do
    it 'returns the segment timeline' do
      expect(video_segment_template.segment_timeline).to be_a(FFMPEG::DASH::SegmentTimeline)
    end
  end

  describe '#segment_query=' do
    it 'sets the segment query' do
      video_segment_template.segment_query = 'foo=bar'
      expect(video_segment_template.initialization).to include('foo=bar')
      expect(video_segment_template.media).to include('foo=bar')
    end
  end
end
