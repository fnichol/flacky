# -*- encoding: utf-8 -*-

require 'flacky/flac_tagger'

module Flacky

  class FlacMetadataImporter

    def initialize(file)
      @file = file
    end

    def import!
      return Resonse.new(nil, 0) if ! File.exists?(metadata_file)

      md = JSON.parse(IO.read(metadata_file))

      elapsed = Benchmark.measure do
        FlacTagger.update(@file) do
          trackn_good = self["TRACKNUMBER"] && self["TRACKNUMBER"].to_i > 0
          discn_good = self["DISCNUMBER"] && self["DISCNUMBER"].to_i > 0
          md_good = md["flac"] && md["flac"]["totaltracks"] \
            && md["flac"]["totaltracks"].is_a?(Array)
          totaltracks = md["flac"]["totaltracks"][self["DISCNUMBER"].to_i - 1]

          %w{artist album genre style mood fileowner}.each do |t|
            tag(t, md["flac"][t]) if md["flac"] && md["flac"][t]
          end

          tag "DATE", md["flac"]["year"] if md["flac"]["year"]

          if trackn_good && discn_good && md_good
            tag('TOTALTRACKS', totaltracks.to_s)
            tag('TOTALDISCS', md["flac"]["totaltracks"].size.to_s)
          end
        end
      end

      Response.new(metadata_file, elapsed.real)
    end

    Response = Struct.new(:metadata_filename, :elapsed)

    private

    def metadata_file
      @metadata_file ||= File.join(File.dirname(@file), "metadata.json")
    end
  end
end
