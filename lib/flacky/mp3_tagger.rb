# -*- encoding: utf-8 -*-

require 'taglib'

module Flacky
  class Mp3Tagger

    def self.update(file, &block)
      instance = self.new(file)
      instance.instance_eval(&block)
      instance.update!
    end

    def initialize(file)
      @taglib = TagLib::MPEG::File.new(file)
      @tag = @taglib.id3v2_tag
    end

    def [](attr)
      result = @tag.field_list_map[attr]

      if result.nil?
        nil
      elsif result.is_a?(Array) && result.size == 1
        result.first
      else
        result
      end
    end

    def find(attr)
      key = @tag.field_list_map.keys.find { |key| key =~ /#{attr}/i }
      key ? self[key] : nil
    end

    def tag(name, value)
      if TAGS.include?(name.to_sym)
        @tag.public_send("#{name}=", value)
      elsif name =~ /track/i
        @tag.add_frame(new_text_frame("TRCK", value))
      elsif name =~ /disc/i
        @tag.add_frame(new_text_frame("TPOS", value))
      elsif name =~ /comment/i
        @tag.add_frame(new_comment_frame(value))
      end
    end

    def cleanup
      @taglib.close
    end

    def update!
      @taglib.save
      cleanup
    end

    private

    TAGS = [:album, :artist, :title, :year, :genre].freeze

    def encoding
      TagLib::String::Latin1
    end

    def new_text_frame(type, value)
      frame = TagLib::ID3v2::TextIdentificationFrame.new(type, encoding)
      frame.text = value
      frame
    end

    def new_comment_frame(value)
      frame = TagLib::ID3v2::CommentsFrame.new
      frame.text_encoding = encoding
      frame.language = "eng"
      frame.text = value
      frame
    end
  end
end
