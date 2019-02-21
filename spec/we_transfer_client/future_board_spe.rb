require 'spec_helper'

describe FutureBoard do
  let(:params) { { name: 'yes', description: 'A description about the board', items: [] } }

  describe '#initializer' do
    it 'raises ArgumentError when no name is given' do
      params.delete(:name)
      expect {
        described_class.new(params)
      }.to raise_exception ArgumentError, /name/
    end

    it 'accepts a blank description' do
      params.delete(:description)
      described_class.new(params)
    end

    it 'accepts a empty array as item argument' do
      expect(described_class.new(params).items).to be_kind_of(Array)
    end
  end

  describe '#to_initial_request_params' do
    it 'has a name' do
      as_params = described_class.new(params).to_initial_request_params
      expect(as_params[:name]).to be_kind_of(String)
    end

    it 'has a description' do
      as_params = described_class.new(params).to_initial_request_params
      expect(as_params[:description]).to be(params[:description])
    end
  end

  describe '#as_json_request_params' do
    it 'has a name' do
      as_params = described_class.new(params).as_json_request_params
      expect(as_params[:name]).to be_kind_of(String)
    end

    it 'has a description' do
      as_params = described_class.new(params).as_json_request_params
      expect(as_params[:description]).to be(params[:description])
    end

    it 'has items' do
      file = FutureFile.new(name: 'yes', io: File.open(__FILE__, 'rb'))
      params[:items] << file
      as_params = described_class.new(params).as_json_request_params
      expect(as_params[:items].count).to be(1)
    end
  end

  describe '#files' do
    it 'returns only file items' do
      file = FutureFile.new(name: 'yes', io: File.open(__FILE__, 'rb'))
      link = FutureLink.new(url: 'https://www.wetransfer.com', title: 'WeTransfer')
      future_board = described_class.new(params)
      3.times do
        future_board.items << file
        future_board.items << link
      end
      expect(future_board.items.size).to eq(6)
      expect(future_board.files.size).to eq(3)
    end
  end

  describe '#links' do
    it 'returns only link items' do
      file = FutureFile.new(name: 'yes', io: File.open(__FILE__, 'rb'))
      link = FutureLink.new(url: 'https://www.wetransfer.com', title: 'WeTransfer')
      future_board = described_class.new(params)
      3.times do
        future_board.items << file
        future_board.items << link
      end
      expect(future_board.items.size).to eq(6)
      expect(future_board.links.size).to eq(3)
    end
  end

  describe 'getters' do
    let(:subject) { described_class.new(params) }

    it '#name' do
      subject.name
    end

    it '#description' do
      subject.description
    end

    it 'items' do
      subject.items
    end
  end
end
