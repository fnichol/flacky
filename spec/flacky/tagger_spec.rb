# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'mocha/setup'
require 'flacky/tagger'

describe Flacky::Tagger do
  let(:flac_file) do
    File.join(File.dirname(__FILE__), '../fixtures/silence.flac')
  end

  let(:tagger) do
    Flacky::Tagger.new(flac_file)
  end

  let(:flacinfo) do
    mock = FlacInfo.new(flac_file)
    mock.stubs(:tags).returns({ 'Title' => 'Silence' })
    mock.stubs(:update!).returns(true)
    mock
  end

  describe "#tag" do
    it "adds a new comment tag if none exist" do
      flacinfo.expects(:comment_add).with('DISCNUMBER=1').returns(true)
      FlacInfo.stubs(:new).returns(flacinfo)

      tagger.tag "DISCNUMBER", "1"
    end

    it "overwrites a comment tag if one exists" do
      flacinfo.expects(:comment_del).with('Title').returns(true)
      flacinfo.expects(:comment_add).with('Title=Le Silence').returns(true)
      FlacInfo.stubs(:new).returns(flacinfo)

      tagger.tag "Title", "Le Silence"
    end
  end

  describe "#update!" do
    it "calls update! on the FlacInfo object" do
      flacinfo.expects(:update!).returns(true)
      FlacInfo.stubs(:new).returns(flacinfo)

      tagger.update!
    end
  end

  describe ".update" do
    it "adds the tag and updates" do
      flacinfo.expects(:comment_add).with('DISCNUMBER=1').returns(true)
      flacinfo.expects(:update!).returns(true)
      FlacInfo.stubs(:new).returns(flacinfo)

      Flacky::Tagger.update(flac_file) do
        tag "DISCNUMBER", "1"
      end
    end
  end

  # it "does stuff" do
  #   Flacky::Tagger.update('file') do
  #     tag 'MOOD', "yep"
  #     tag 'FILEOWNER', "fletcher"
  #   end
  # end
end
