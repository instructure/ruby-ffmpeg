# frozen_string_literal: true

module FFMPEG
  class Error < StandardError
  end

  class HTTPTooManyRedirects < StandardError
  end
end
