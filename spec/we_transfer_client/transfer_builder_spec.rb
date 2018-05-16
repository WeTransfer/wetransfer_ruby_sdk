require 'spec_helper'

describe TransferBuilder do
  it 'fails if given an item with a size of 0' do
    broken = StringIO.new('')
    expect { 
      described_class.new.ensure_io_compliant!(broken)
    }.to raise_error(/The IO object given to add_file has a size of 0/)
  end
end