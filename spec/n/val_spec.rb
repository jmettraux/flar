
#
# specifying flor
#
# Thu Jan  7 06:22:04 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'val' do

    it 'returns values on their own' do

      rad = %{
        val 3
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => 3 })
    end

    it 'returns values on their own (arrays)' do

      rad = %{
        val [ 'a' b 3 ]
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => [ 'a', 'b', 3 ] })
    end
  end
end

