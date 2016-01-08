
#
# specifying flor
#
# Thu Jan  7 06:22:04 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  describe 'push' do

    it 'pushes to a field' do

      rad = %{
        push l 1
      }

      r = Flor.eval(rad, {}, {})

      expect(r).to eq(:x)
    end

    it 'pushes $(ret) when no attributes'
    it 'fails if the target is not an array'

#    it 'returns values on their own' do
#
#      cmp = %{
#        2
#      }
#
#
#      expect(r['point']).to eq('terminated')
#      #expect(r['exid']).to eq(exid)
#      expect(r['from']).to eq(nil)
#      #expect(r['n']).to eq(3)
#      expect(r['payload']).to eq({ 'ret' => 2 })
#    end
  end
end

