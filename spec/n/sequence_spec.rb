
#
# specifying flor
#
# Sat Jan  9 07:20:32 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  describe 'sequence' do

    it 'returns immediately if empty'

    it 'chains instructions' do

      rad = %{
        sequence
          1
          2
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 2 })
    end

    it 'returns the value of last child as $(ret)'

#    it 'returns values on their own' do
#
#      rad = %{
#        2
#      }
#
#      r = Flor.eval(rad, {}, {})
#
#      expect(r['point']).to eq('terminated')
#      #expect(r['exid']).to eq(exid)
#      expect(r['from']).to eq(nil)
#      #expect(r['n']).to eq(3)
#      expect(r['payload']).to eq({ 'ret' => 2 })
#    end
  end
end

