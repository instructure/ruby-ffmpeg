# frozen_string_literal: true

require_relative 'command_args'

module FFMPEG
  # The Filter class represents a ffmpeg filter
  # that can be applied to a stream.
  #
  # @example
  #  filter = FFMPEG::Filter.new(:video, 'scale', w: -2, h: 720)
  #  filter.to_s # => "scale=w=-2:h=720"
  #  filter.with_input_link('0:v').with_output_link('v0').to_s # => "[0:v]scale=w=-2:h=720[v0]"
  class Filter
    class << self
      # Join the filters together into a filter chain
      # that can be applied to a stream.
      #
      # @param filters [Array<Filter>] The filters to join.
      # @return [String] The filter chain.
      def join(*filters)
        filters.compact.map(&:to_s).join(',')
      end
    end

    attr_reader :type, :name, :kwargs, :input_links, :output_links

    # @param type [Symbol] The type of the filter (must be one of :video or :audio).
    # @param name [String] The name of the filter (e.g.: 'scale', 'volume').
    # @param kwargs [Hash] The keyword arguments to use for the filter.
    def initialize(type, name, **kwargs)
      raise ArgumentError, "Unknown type #{type}, expected :video or :audio" unless %i[audio video].include?(type)
      raise ArgumentError, "Unknown name format #{name.class}, expected #{String}" unless name.is_a?(String)

      @type = type
      @name = name

      kwargs = kwargs.compact
      @kwargs = kwargs unless kwargs.empty?

      @input_links = []
      @output_links = []
    end

    # Clone the filter.
    def clone
      super.tap do |filter|
        filter.instance_variable_set(:@input_links, @input_links.clone)
        filter.instance_variable_set(:@output_links, @output_links.clone)
      end
    end

    # Convert the filter to a string.
    #
    # @return [String] The filter as a string.
    def to_s
      [
        format_input_links,
        [@name, format_kwargs].reject(&:empty?).join('='),
        format_output_links
      ].join
    end

    # Clone the filter with the specified input links.
    #
    # @param stream_ids [Array<String>] The stream IDs to use as input links.
    # @return [Filter] The cloned filter.
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_input_links('0:a:0').to_s # => "[0:a:0]silencedetect"
    def with_input_links(*stream_ids)
      clone.with_input_links!(*stream_ids)
    end

    # Set the specified input links on the filter.
    # This will replace any existing input links.
    #
    # @param stream_ids [Array<String>] The stream IDs to use as input links.
    # @return [self]
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_input_links!('0:a:0')
    #  filter.to_s # => "[0:a:0]silencedetect"
    def with_input_links!(*stream_ids)
      @input_links = []
      stream_ids.each(&method(:with_input_link!))
      self
    end

    # Clone the filter with the specified input link.
    # This will add the input link to the existing input links.
    #
    # @param stream_id [String] The stream ID to use as input link.
    # @return [Filter] The cloned filter.
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_input_link('0:a:0').to_s # => "[0:a:0]silencedetect"
    def with_input_link(stream_id)
      clone.with_input_link!(stream_id)
    end

    # Add the specified input link to the filter.
    #
    # @param stream_id [String] The stream ID to use as input link.
    # @return [self]
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_input_link!('0:a:0')
    #  filter.to_s # => "[0:a:0]silencedetect"
    def with_input_link!(stream_id)
      unless stream_id.is_a?(String)
        raise ArgumentError,
              "Unknown stream_id format #{stream_id.class}, expected #{String}"
      end

      @input_links << stream_id
      self
    end

    # Clone the filter with the specified output links.
    # This will replace any existing output links.
    #
    # @param stream_ids [Array<String>] The stream IDs to use as output links.
    # @return [Filter] The cloned filter.
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_output_links('a0', 'a1').to_s # => "silencedetect[a0][a1]"
    def with_output_links(*stream_ids)
      clone.with_output_links!(*stream_ids)
    end

    # Set the specified output links on the filter.
    # This will replace any existing output links.
    #
    # @param stream_ids [Array<String>] The stream IDs to use as output links.
    # @return [self]
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_output_links!('a0', 'a1')
    #  filter.to_s # => "silencedetect[a0][a1]"
    def with_output_links!(*stream_ids)
      @output_links = []
      stream_ids.each(&method(:with_output_link!))
      self
    end

    # Clone the filter with the specified output link.
    # This will add the output link to the existing output links.
    #
    # @param stream_id [String] The stream ID to use as output link.
    # @return [Filter] The cloned filter.
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_output_link('a0').to_s # => "silencedetect[a0]"
    def with_output_link(stream_id)
      clone.with_output_link!(stream_id)
    end

    # Add the specified output link to the filter.
    #
    # @param stream_id [String] The stream ID to use as output link.
    # @return [self]
    #
    # @example
    #  filter = FFMPEG::Filter.new(:audio, 'silencedetect')
    #  filter.with_output_link!('a0')
    #  filter.to_s # => "silencedetect[a0]"
    def with_output_link!(stream_id)
      unless stream_id.is_a?(String)
        raise ArgumentError,
              "Unknown stream_id format #{stream_id.class}, expected #{String}"
      end

      @output_links << stream_id
      self
    end

    protected

    def format_kwargs(kwargs = @kwargs)
      CommandArgs.format_kwargs(kwargs)
    end

    def format_input_links
      format_links(@input_links)
    end

    def format_output_links
      format_links(@output_links)
    end

    def format_links(links)
      links.map { |link| "[#{link}]" }.join
    end
  end
end
