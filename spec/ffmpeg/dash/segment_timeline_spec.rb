# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::SegmentTimeline do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }

  let(:segment_timeline) do
    manifest
      .adaptation_sets
      .first
      .representations
      .first
      .segment_template
      .segment_timeline
  end

  describe '#to_ranges' do
    subject { segment_timeline.to_ranges.to_a }

    it 'returns the segment timeline ranges' do
      is_expected.to eq([0..270_000, 270_000..540_000, 810_000..909_000])
    end
  end
end
