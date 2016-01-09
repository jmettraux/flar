
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

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'l' => [ 1 ] })
    end

    it 'fails if the target is not an array'
    it 'pushes $(ret) when no attributes'
  end
end

