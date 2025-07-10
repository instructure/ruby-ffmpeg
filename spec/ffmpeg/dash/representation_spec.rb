# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe FFMPEG::DASH::Representation do
  let(:path) { 'spec/fixtures/media/dash.mpd' }
  let(:manifest) { FFMPEG::DASH::Manifest.parse(File.read(path)) }
  let(:video_representation) { manifest.adaptation_sets.find { |s| s.content_type == 'video' }.representations.first }
  let(:audio_representation) { manifest.adaptation_sets.find { |s| s.content_type == 'audio' }.representations.first }

  describe '#id' do
    it 'returns the id' do
      expect(video_representation.id).to eq(0)
      expect(audio_representation.id).to eq(2)
    end
  end

  describe '#mime_type' do
    it 'returns the mime type' do
      expect(video_representation.mime_type).to eq('video/mp4')
      expect(audio_representation.mime_type).to eq('audio/mp4')
    end
  end

  describe '#codecs' do
    it 'returns the codecs' do
      expect(video_representation.codecs).to eq('avc1.640028')
      expect(audio_representation.codecs).to eq('mp4a.40.2')
    end
  end

  describe '#bandwidth' do
    it 'returns the bandwidth' do
      expect(video_representation.bandwidth).to eq(2_500_000)
      expect(audio_representation.bandwidth).to eq(128_000)
    end
  end

  describe '#sar' do
    subject { video_representation.sar }

    it 'returns the sar' do
      is_expected.to eq('1:1')
    end
  end

  describe '#width' do
    subject { video_representation.width }

    it 'returns the width' do
      is_expected.to eq(1920)
    end
  end

  describe '#height' do
    subject { video_representation.height }

    it 'returns the height' do
      is_expected.to eq(1080)
    end
  end

  describe '#resolution' do
    it 'returns the resolution based on width and height' do
      expect(video_representation.resolution).to eq('1920x1080')
      expect(audio_representation.resolution).to be_nil
    end
  end

  describe '#segment_template' do
    subject { video_representation.segment_template }

    it 'returns the segment template' do
      is_expected.to be_a(FFMPEG::DASH::SegmentTemplate)
    end
  end

  describe '#base_url' do
    before do
      video_representation.add_child('<BaseURL>http://example.com/</BaseURL>')
    end

    it 'returns the base url' do
      expect(video_representation.base_url).to eq('http://example.com/')
      expect(audio_representation.base_url).to be_nil
    end
  end

  describe '#base_url=' do
    it 'sets the base url' do
      video_representation.base_url = 'http://example.com/'
      expect(video_representation.at_xpath('.//xmlns:BaseURL').content).to eq('http://example.com/')
    end
  end

  describe '#segment_query=' do
    it 'sets the segment query' do
      video_representation.segment_query = 'foo=bar'
      expect(video_representation.segment_template.initialization).to match(/\?foo=bar$/)
      expect(video_representation.segment_template.media).to match(/\?foo=bar$/)
    end
  end

  describe '#to_ranges' do
    it 'returns the segment ranges' do
      expect(video_representation.to_ranges.to_a).to eq(
        [0.0..3.0, 3.0..6.0, 9.0..10.1]
      )
      expect(audio_representation.to_ranges.to_a).to eq(
        [0.0..2.98958, 2.98958..5.98958, 5.98958..8.98958, 8.98958..10.1]
      )
    end
  end

  describe '#to_m3u8' do
    subject { representation.to_m3u8 }

    context 'with video representation' do
      let(:representation) { video_representation }

      it 'returns M3U8 playlist for video representation' do
        is_expected.to eq(<<~M3U8.strip)
          #EXTM3U
          #EXT-X-VERSION:6
          #EXT-X-TARGETDURATION:3
          #EXT-X-PLAYLIST-TYPE:VOD
          #EXT-X-MAP:URI="init-stream0.m4s"
          #EXTINF:3.0,
          chunk-stream0-00001.m4s
          #EXTINF:3.0,
          chunk-stream0-00002.m4s
          #EXTINF:1.1,
          chunk-stream0-00003.m4s
          #EXT-X-ENDLIST
        M3U8
      end
    end

    context 'with audio representation' do
      let(:representation) { audio_representation }

      it 'returns M3U8 playlist for audio representation' do
        is_expected.to eq(<<~M3U8.strip)
          #EXTM3U
          #EXT-X-VERSION:6
          #EXT-X-TARGETDURATION:3
          #EXT-X-PLAYLIST-TYPE:VOD
          #EXT-X-MAP:URI="init-stream2.m4s"
          #EXTINF:2.98958,
          chunk-stream2-00001.m4s
          #EXTINF:3.0,
          chunk-stream2-00002.m4s
          #EXTINF:3.0,
          chunk-stream2-00003.m4s
          #EXTINF:1.11042,
          chunk-stream2-00004.m4s
          #EXT-X-ENDLIST
        M3U8
      end
    end

    context 'with base URL set' do
      let(:representation) { video_representation }

      before { representation.base_url = 'http://example.com/dash/' }

      it 'includes base URL in segment URLs' do
        expect(subject).to include('URI="http://example.com/dash/init-stream0.m4s"')
        expect(subject).to include('http://example.com/dash/chunk-stream0-00001.m4s')
      end
    end

    context 'with dynamic manifest' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="dynamic">
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
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:representation) { manifest.adaptation_sets.first.representations.first }

      it 'excludes VOD-specific tags' do
        expect(subject).not_to include('#EXT-X-PLAYLIST-TYPE:VOD')
        expect(subject).not_to include('#EXT-X-ENDLIST')
      end
    end

    context 'with unsupported content types' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="subtitle">
                <Representation id="0" mimeType="text/vtt" bandwidth="1000">
                  <SegmentTemplate initialization="init.m4s" media="chunk.m4s">
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
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:representation) { manifest.adaptation_sets.first.representations.first }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when no segment template is present' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="video">
                <Representation id="0" mimeType="video/mp4" codecs="avc1.640028" bandwidth="2500000" width="1920" height="1080">
                </Representation>
              </AdaptationSet>
            </Period>
          </MPD>
        XML
      end
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:representation) { manifest.adaptation_sets.first.representations.first }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#to_m3u8si' do
    subject { representation.to_m3u8si(audio_group_id: audio_group_id, video_group_id: video_group_id) }

    let(:audio_group_id) { nil }
    let(:video_group_id) { nil }

    context 'with video representation' do
      let(:representation) { video_representation }
      let(:audio_group_id) { 'audio' }

      it 'returns an HLS EXT-X-STREAM-INF tag' do
        is_expected.to eq(<<~M3U8.strip)
          #EXT-X-STREAM-INF:BANDWIDTH=2500000,CODECS="avc1.640028",RESOLUTION=1920x1080,AUDIO="audio"
          stream0.m3u8
        M3U8
      end
    end

    context 'with audio representation' do
      let(:representation) { audio_representation }

      it 'returns an HLS EXT-X-STREAM-INF tag without resolution' do
        is_expected.to eq(<<~M3U8.strip)
          #EXT-X-STREAM-INF:BANDWIDTH=128000,CODECS="mp4a.40.2"
          stream2.m3u8
        M3U8
      end
    end

    context 'with video group ID parameter' do
      let(:representation) { video_representation }
      let(:video_group_id) { 'video' }

      it 'includes video group ID' do
        expect(subject).to include('VIDEO="video"')
      end
    end

    context 'with unsupported content types' do
      let(:mpd) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static">
            <Period>
              <AdaptationSet id="0" contentType="subtitle">
                <Representation id="0" mimeType="text/vtt" bandwidth="1000">
                  <SegmentTemplate initialization="init.m4s" media="chunk.m4s">
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
      let(:manifest) { FFMPEG::DASH::Manifest.parse(mpd) }
      let(:representation) { manifest.adaptation_sets.first.representations.first }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end
end
