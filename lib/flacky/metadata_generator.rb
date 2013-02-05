# -*- encoding: UTF-8 -*-

require 'taglib'
require 'shellwords'

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
      flacs = Dir.glob(File.join(dir.shellescape, '*.flac'))
      return Hash.new if flacs.empty?

      result = Hash.new
      result["totaltracks"] = []

      flacs.each do |flac|
        md = read_flac_metadata(flac)
        track_total = (md["totaltracks"] || -1).to_i
        disc_number = (md["discnumber"] || -1).to_i

        next if track_total < 0 || disc_number < 0
        next if result["totaltracks"][disc_number - 1]

        result["totaltracks"][disc_number - 1] = track_total

        common_tags.each { |t| result[t] = md[t] if md[t] }
      end
      result["year"] = result.delete("date") if result["date"]

      result
    end

    def scraped_metadata
      url = file_metadata["allmusic_url"]
      return Hash.new if !url || (url && url.empty?)

      scraper = Flacky::Scraper.new(url)
      { 'style' => scraper.styles.join(';'), 'mood' => scraper.moods.join(';') }
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
      %w[artist album date year genre style mood fileowner].freeze
    end

    def read_flac_metadata(flac)
      info = TagLib::FLAC::File.open(flac) do |file|
        file.xiph_comment.field_list_map
      end

      info.each_pair do |k, v|
        value = Array(v).first
        value.force_encoding('UTF-8') if v.is_a? String
        info[k] = value
      end
      info.keys.each do |key|
        info[key.downcase] = info.delete(key)
      end

      info
    end
  end
end
