# frozen_string_literal: true

require_relative '../../spec_helper'

module FFMPEG
  class CommandArgs
    describe NetworkStreaming do
      let(:path) { fixture_media_file('napoleon.mp3', remote: true) }
      let(:media) { FFMPEG::Media.new(path) }

      subject(:args) do
        CommandArgs.compose(media) do
          use NetworkStreaming
        end.to_a
      end

      before { start_web_server }
      after { stop_web_server }

      context 'when the media is not remote' do
        let(:path) { fixture_media_file('napoleon.mp3') }

        it 'does not apply network streaming arguments' do
          expect(args).to be_empty
        end
      end

      context 'when the media is remote' do
        it 'applies network streaming arguments' do
          expect(args).to(
            eq(
              %w[
                -reconnect 1
                -reconnect_at_eof 1
                -reconnect_streamed 1
                -reconnect_on_network_error 1
                -reconnect_on_http_error 500,502,503,504
                -reconnect_delay_max 30
              ]
            )
          )
        end
      end
    end
  end
end
