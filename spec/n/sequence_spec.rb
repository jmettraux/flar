
#
# specifying flor
#
# Sat Jan  9 07:20:32 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'sequence' do

    it 'returns immediately if empty' do

      rad = %{
        sequence
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({})
    end

    it 'chains instructions' do

      rad = %{
        sequence
          push l 0
          push l 1
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'l' => [ 0, 1 ], 'ret' => 1 })
    end

    it 'returns the value of last child as $(ret)' do

      rad = %{
        sequence
          1
          2
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 2 })
    end
  end
end

