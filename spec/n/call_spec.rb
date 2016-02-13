
#
# specifying flor
#
# Sat Feb 13 16:26:52 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'call' do

    it 'calls a function' do

      rad = %{
        sequence
          define push1
            push l 1
          call push1
          call push1
      }

      r = @executor.launch(rad)
pp r

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => 1 })
    end
  end
end

