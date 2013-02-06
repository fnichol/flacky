# -*- encoding: UTF-8 -*-

require 'flacky/flac_tagger'

module Flacky

  class FlacTrackZeroPadStripper

    def initialize(file)
      @file = file
    end

    def strip!
      number = fetch_tracknumber
      return if number.nil?

      if number.to_s =~ /^0\d/
        FlacTagger.update(@file) do
          tag 'TRACKNUMBER', number.to_s.sub(/^0/, '')
        end
      end
    end

    private

    def fetch_tracknumber
      tagger = FlacTagger.new(@file)
      track = tagger.find(:tracknumber)
      tagger.cleanup
      track
    end
  end
end
