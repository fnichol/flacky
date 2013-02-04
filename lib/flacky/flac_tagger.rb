# -*- encoding: utf-8 -*-

require 'taglib'

module Flacky
  class FlacTagger

    def self.update(file, &block)
      instance = self.new(file)
      instance.instance_eval(&block)
      instance.update!
    end

    def initialize(file)
      @taglib = TagLib::FLAC::File.new(file)
      @tag = @taglib.xiph_comment
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
      @tag.add_field(name.to_s.upcase, value, true)
    end

    def cleanup
      @taglib.close
    end

    def update!
      @taglib.save
      cleanup
    end
  end
end
