require 'spec_helper'

describe WeTransfer::BoardBuilder do
  let(:client) { WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY')) }
  let(:subject) { described_class.new(client: client) }
  describe '#initialize' do
    it 'initializes with instance variable @files' do
      expect(subject.instance_variables).to include(:@files)
    end

    it 'initializes with an empty files array' do
      expect(subject.files.empty?).to be_truthy
      expect(subject.files).to be_a_kind_of(Array)
    end

    it 'initializes with instance variable @links' do
      expect(subject.instance_variables).to include(:@links)
    end

    it 'initializes with an empty links array' do
      expect(subject.links.empty?).to be_truthy
      expect(subject.links).to be_a_kind_of(Array)
    end
  end

  describe '#items' do
    it 'returns empty when no files or links are added to board_builder' do
      expect(subject.items).to be_empty
    end

    it 'is an array of files and links' do
      subject.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
      subject.add_web_url(url: 'https://www.developers.wetransfer.com')
      expect(subject.items).to be_kind_of(Array)
      expect(subject.items.map(&:class)).to include(WeTransfer::FutureFile, WeTransfer::FutureLink)
    end

    it 'knows how many items were added' do
      subject.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
      subject.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Website')
      expect(subject.items.count).to be(2)
    end
  end

  describe '#add_file' do
    before do
      subject.add_file(name: File.basename(__FILE__), size: File.size(__FILE__))
    end

    it 'returns an error when name is missing' do
      expect {
        subject.add_file(size: File.size(__FILE__))
      }.to raise_error ArgumentError, /name/
    end

    it 'returns an error when size is missing' do
      expect {
        subject.add_file(name: File.basename(__FILE__))
      }.to raise_error ArgumentError, /size/
    end

    it 'adds a file when name and size is given' do
      expect(subject.items.first).to be_kind_of(WeTransfer::FutureFile)
      expect(subject.files.count).to be(1)
    end
  end

  describe '#add_file_at' do
    before do
      subject.add_file_at(path: __FILE__)
    end

    it 'adds a file from a path' do
      expect(subject.items.first).to be_kind_of(WeTransfer::FutureFile)
    end

    it 'adds a file to the files array' do
      expect(subject.files.first).to be_kind_of(WeTransfer::FutureFile)
    end

    it 'takes the name of the file when path is given' do
      expect(subject.files.first.name).to eq(File.basename(__FILE__))
    end

    it 'takes the size of the file when path is given' do
      expect(subject.files.first.size).to eq(File.size(__FILE__))
    end

    it 'throws a Error when file doesnt exists' do
      expect {
        subject.add_file_at(path: '/this/path/leads/to/nothing.exe')
      }.to raise_error Errno::ENOENT
    end
  end

  describe '#add_web_url' do
    before do
      subject.add_web_url(url: 'https://www.developers.wetransfer.com', title: 'WeTransfer Dev Portal')
    end

    it 'adds a item to board when url and title are given' do
      expect(subject.items.first).to be_kind_of(WeTransfer::FutureLink)
    end

    it 'adds a link to board when url and title are given' do
      expect(subject.links.first).to be_kind_of(WeTransfer::FutureLink)
    end

    it 'takes the url as title when no title is given' do
      subject.add_web_url(url: 'https://www.developers.wetransfer.com')
      expect(subject.links.last.title).to eq('https://www.developers.wetransfer.com')
    end

    it 'raises an error when no url is given' do
      expect {
        subject.add_web_url(title: 'https://www.developers.wetransfer.com')
      }.to raise_error ArgumentError, /url/
    end
  end

  describe '#select_file_on_name' do
    before do
      subject.add_file_at(path: __FILE__)
    end

    it 'selects a file based on name' do
      found_file = subject.select_file_on_name(name: File.basename(__FILE__))
      expect(found_file).to be_kind_of(WeTransfer::FutureFile)
      expect(found_file.name).to eq(File.basename(__FILE__))
    end

    it 'raises an error when file not found' do
      expect {
        subject.select_file_on_name(name: 'foo.jpg')
      }.to raise_error WeTransfer::TransferIOError
    end
  end

  describe '#getters' do
    %i(files links items).each do |getter|
      it "responds to ##{getter}" do
        subject.send getter
      end
    end
  end
end
