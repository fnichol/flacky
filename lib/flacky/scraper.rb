# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'open-uri'

module Flacky
  class Scraper

    def initialize(url)
      @url = url
    end

    def styles
      doc.css('#sidebar .styles ul a').map { |link| link.content }.sort
    end

    def moods
      doc.css('#sidebar .moods ul a').map { |link| link.content }.sort
    end

    private

    def doc
      @doc ||= Nokogiri::HTML(open(@url))
    end
  end
end
