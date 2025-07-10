# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::Manifest do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { described_class.parse(File.read(path)) }

  describe '#type' do
    subject { manifest.type }

    it 'returns static' do
      is_expected.to eq('static')
    end
  end

  describe '#vod?' do
    subject { manifest.vod? }

    context 'for static manifests' do
      it 'returns true' do
        is_expected.to be true
      end
    end

    context 'for dynamic manifests' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="dynamic">
          </MPD>
        XML
      end
      let(:manifest) { described_class.parse(mpd) }

      it 'returns false' do
        is_expected.to be false
      end
    end
  end

  describe '#adaptation_sets' do
    subject { manifest.adaptation_sets }

    it 'returns the adaptation sets' do
      expect(subject.count).to eq(2)
    end
  end

  describe '#base_url=' do
    it 'sets the base url on all representations' do
      manifest.base_url = 'http://example.com/'
      manifest.adaptation_sets.each do |adaptation_set|
        adaptation_set.representations.each do |representation|
          expect(representation.at_xpath('.//xmlns:BaseURL').content).to eq('http://example.com/')
        end
      end
    end
  end

  describe '#segment_query=' do
    it 'sets the segment query on all segment templates' do
      manifest.segment_query = 'foo=bar'
      manifest.adaptation_sets.each do |adaptation_set|
        adaptation_set.representations.each do |representation|
          expect(representation.segment_template.initialization).to match(/\?foo=bar$/)
          expect(representation.segment_template.media).to match(/\?foo=bar$/)
        end
      end
    end
  end

  describe '#to_xml' do
    subject { manifest.to_xml.strip }

    it 'returns the original XML content' do
      is_expected.to eq(File.read(path).strip)
    end
  end

  describe '#to_m3u8' do
    subject { manifest.to_m3u8 }

    context 'with both audio and video content' do
      it 'returns the MPD as an HLS playlist' do
        is_expected.to eq(<<~M3U8.strip)
          #EXTM3U
          #EXT-X-VERSION:6
          #EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=audio,NAME="und",LANGUAGE="und",DEFAULT=YES,AUTOSELECT=YES,URI="stream2.m3u8"
          #EXT-X-STREAM-INF:BANDWIDTH=2500000,CODECS="avc1.640028",RESOLUTION=1920x1080,AUDIO="audio"
          stream0.m3u8
          #EXT-X-STREAM-INF:BANDWIDTH=1250000,CODECS="avc1.640028",RESOLUTION=1280x720,AUDIO="audio"
          stream1.m3u8
        M3U8
      end
    end

    context 'with only video content' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="video">
                <Representation id="0" mimeType="video/mp4" codecs="avc1.640028" bandwidth="2500000" width="1920" height="1080">
                  <SegmentTemplate timescale="90000" initialization="init.m4s" media="chunk$Number$.m4s">
                    <SegmentTimeline>
                      <S t="0" d="270000"/>
                    </SegmentTimeline>
                  </SegmentTemplate>
                </Representation>
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { described_class.parse(mpd) }

      it 'returns an HLS playlist without EXT-X-MEDIA tag' do
        is_expected.to eq(<<~M3U8.strip)
          #EXTM3U
          #EXT-X-VERSION:6
          #EXT-X-STREAM-INF:BANDWIDTH=2500000,CODECS="avc1.640028",RESOLUTION=1920x1080
          stream0.m3u8
        M3U8
      end
    end

    context 'with only audio content' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="audio" lang="en">
                <Representation id="0" mimeType="audio/mp4" codecs="mp4a.40.2" bandwidth="128000">
                  <SegmentTemplate timescale="48000" initialization="init.m4s" media="chunk$Number$.m4s">
                    <SegmentTimeline>
                      <S t="0" d="143500"/>
                    </SegmentTimeline>
                  </SegmentTemplate>
                </Representation>
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { described_class.parse(mpd) }

      it 'returns an HLS playlist without EXT-X-MEDIA tag' do
        is_expected.to eq(<<~M3U8.strip)
          #EXTM3U
          #EXT-X-VERSION:6
          #EXT-X-STREAM-INF:BANDWIDTH=128000,CODECS="mp4a.40.2"
          stream0.m3u8
        M3U8
      end
    end

    context 'with no supported content' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { described_class.parse(mpd) }

      it 'returns a minimal HLS playlist' do
        is_expected.to eq(<<~M3U8.strip)
          #EXTM3U
          #EXT-X-VERSION:6
        M3U8
      end
    end
  end
end
