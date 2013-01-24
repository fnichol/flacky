# -*- encoding: UTF-8 -*-

require 'flacinfo'

require 'flacky/core_ext'
require 'flacky/scraper'

module Flacky
  class MetadataGenerator
    attr_reader :dir, :metadata_file, :file_metadata

    def initialize(metadata_file)
      @metadata_file = metadata_file
      @dir = File.dirname(@metadata_file)
      @file_metadata = load_file_metadata
    end

    def flac_metadata
      flacs = Dir.glob(File.join(dir, '*.flac'))
      return Hash.new if flacs.empty?

      # keep trying flac files until we run out
      info = begin
        FlacInfo.new(flacs.shift).tags
      rescue FlacInfoReadError => ex
        flacs.size > 0 ? retry : Hash.new
      end

      info.each_pair { |k,v| v.force_encoding('UTF-8') if v.is_a? String }
      result = Hash.new
      common_tags.each { |t| result[t] = info[t] }
      result
    end

    def scraped_metadata
      url = file_metadata["allmusic_url"]
      return Hash.new if !url || (url && url.empty?)

      scraper = Flacky::Scraper.new(url)
      { 'STYLE' => scraper.styles.join(';'), 'MOOD' => scraper.moods.join(';') }
    end

    def combined_data
      result = { "allmusic_url" => "" }
      result["flac"] = (result["flac"] || Hash.new).merge(flac_metadata)
      result = result.deep_merge(file_metadata)
      result["flac"] = result["flac"].merge(scraped_metadata)
      result
    end

    private

    def load_file_metadata
      File.exists?(metadata_file) ? JSON.parse(IO.read(metadata_file)) : Hash.new
    end

    def common_tags
      %w[Artist Album Date Genre TOTALDISCS STYLE MOOD FILEOWNER].freeze
    end
  end
end
