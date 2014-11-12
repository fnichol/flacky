# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'openssl'
require 'open-uri'
require 'net/http'

module Flacky
  class ScraperError < RuntimeError ; end

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

    HTTP_ERRORS = [::Timeout::Error, ::Errno::EINVAL, ::Errno::ECONNRESET,
      ::EOFError, ::Net::HTTPBadResponse, ::Net::HTTPHeaderSyntaxError,
      ::Net::ProtocolError, ::SocketError, ::OpenSSL::SSL::SSLError,
      ::Errno::ECONNREFUSED]

    def doc
      @doc ||= begin
        Nokogiri::HTML(open(@url))
      rescue *HTTP_ERRORS => ex
        raise Flacky::ScraperError, "#{ex.class.name}: #{ex.message}"
      end
    end
  end
end
