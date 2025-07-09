# frozen_string_literal: true

require_relative '../../spec_helper'

describe FFMPEG::DASH::SegmentTimeline do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }

  let(:video_segment_timeline) do
    manifest
      .adaptation_sets
      .find { _1.content_type == 'video' }
      .representations
      .first
      .segment_template
      .segment_timeline
  end

  let(:audio_segment_timeline) do
    manifest
      .adaptation_sets
      .find { _1.content_type == 'audio' }
      .representations
      .first
      .segment_template
      .segment_timeline
  end

  before do
    video_segment_timeline['timescale'] = 10_000
  end

  describe '#timescale' do
    it 'returns the timescale' do
      expect(video_segment_timeline.timescale).to eq(10_000)
      expect(audio_segment_timeline.timescale).to eq(1)
    end
  end

  describe '#to_ranges' do
    it 'returns the segment ranges' do
      expect(video_segment_timeline.to_ranges.to_a).to eq(
        [0.0..27.0, 27.0..54.0, 81.0..90.9]
      )

      expect(audio_segment_timeline.to_ranges.to_a).to eq(
        [0.0..143_500.0, 143_500.0..287_500.0, 287_500.0..431_500.0, 431_500.0..484_800.0]
      )
    end
  end
end
