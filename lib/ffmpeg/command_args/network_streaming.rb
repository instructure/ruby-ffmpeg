# frozen_string_literal: true

require_relative 'composable'

module FFMPEG
  class CommandArgs
    # The NetworkStreaming composable contains some defaults
    # for network streaming operations.
    # This composable is best used as an input argument composer.
    module NetworkStreaming
      include FFMPEG::CommandArgs::Composable

      compose do
        next unless media.remote?

        reconnect 1
        reconnect_at_eof 1
        reconnect_streamed 1
        reconnect_on_network_error 1
        reconnect_on_http_error '500,502,503,504'
        reconnect_delay_max 30
      end
    end
  end
end
