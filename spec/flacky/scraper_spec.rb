# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'vcr'
require 'webmock/minitest'
require 'flacky/scraper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

describe Flacky::Scraper do
  WRAPPED_ERRORS = [
    Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
    Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
    SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED
  ]

  ALBUM_DATA = {
    :rush_moving_pictures => {
      :url => "http://www.allmusic.com/album/moving-pictures-mw0000616962",
      :styles => [
        "Album Rock", "Arena Rock", "Hard Rock", "Prog-Rock"
      ],
      :moods => [
        "Aggressive", "Ambitious", "Atmospheric", "Cerebral", "Complex",
        "Confident", "Difficult", "Dramatic", "Earnest", "Elaborate",
        "Energetic", "Enigmatic", "Epic", "Fierce", "Fiery", "Intense",
        "Literate", "Lively", "Plaintive", "Provocative", "Reflective",
        "Sprawling", "Swaggering", "Tense/Anxious", "Theatrical", "Urgent",
        "Visceral", "Volatile"
      ]
    },
    :audioslave_revelations => {
      :url => "http://www.allmusic.com/album/revelations-mw0000451121",
      :styles => [
        "Alternative Metal", "Hard Rock", "Heavy Metal", "Post-Grunge"
      ],
      :moods => [
        "Aggressive", "Angst-Ridden", "Anguished/Distraught", "Brooding",
        "Cerebral", "Confrontational", "Cynical/Sarcastic", "Dramatic",
        "Fiery", "Harsh", "Intense", "Literate", "Manic", "Menacing",
        "Ominous", "Provocative", "Rebellious", "Searching", "Street-Smart",
        "Tense/Anxious", "Uncompromising", "Volatile", "Wry",
      ]
    },
    :bend_sinister_small_fame => {
      :url => "http://www.allmusic.com/album/small-fame-mw0002374964",
      :styles => [
        "Alternative/Indie Rock"
      ],
      :moods => [
      ]
    },
  }

  ALBUM_DATA.each_pair do |cassette, album|
    it "#styles returns a sorted array of styles (#{cassette})" do
      VCR.use_cassette(cassette) do
        Flacky::Scraper.new(album[:url]).styles.must_equal album[:styles]
      end
    end

    it "#moods returns a sorted array of moods (#{cassette})" do
      VCR.use_cassette(cassette) do
        Flacky::Scraper.new(album[:url]).moods.must_equal album[:moods]
      end
    end
  end

  WRAPPED_ERRORS.each do |error|
    it "#styles wraps #{error} and raises a ScraperError" do
      stub_request(:get, "http://www.allmusic.com/uhoh").to_raise(error)
      scraper = Flacky::Scraper.new("http://www.allmusic.com/uhoh")

      proc { scraper.styles }.must_raise(Flacky::ScraperError)
    end
  end
end
