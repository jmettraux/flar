
#
# specifying flor
#
# Thu Jan  7 06:22:04 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  describe 'val' do

    it 'returns values on their own' do

      rad = %{
        2
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      #expect(r['exid']).to eq(exid)
      expect(r['from']).to eq(nil)
      #expect(r['n']).to eq(3)
      expect(r['payload']).to eq({ 'ret' => 2 })
    end
  end
end

