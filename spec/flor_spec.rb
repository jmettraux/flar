
#
# specifying flor
#
# Sun Feb  7 14:27:04 JST 2016
#

require 'spec_helper'


describe Flor do

  before :each do

    @cars = {
      'alpha' => { 'id' => 'FR1' },
      'bentley' => %w[ blower spur markv ]
    }
    @ranking = %w[ Anh Bob Charly ]
  end

  describe '.deep_get' do

    [

      [ :cars, 'simca', true, nil ],
      [ :cars, 'alpha', true, { 'id' => 'FR1' } ],
      [ :cars, 'alpha.id', true, 'FR1' ],

      [ :cars, 'bentley.1', true, 'spur' ],
      [ :cars, 'bentley.other', true, nil ],
      [ :cars, 'bentley.other.nada', false, nil ],

      [ :ranking, '0', true, 'Anh' ],
      [ :ranking, '1', true, 'Bob' ],
      [ :ranking, '-1', true, 'Charly' ],
      [ :ranking, '-2', true, 'Bob' ],
      [ :ranking, 'first', true, 'Anh' ],
      [ :ranking, 'last', true, 'Charly' ],

    ].each do |o, k, b, v|

      it "gets #{k.inspect}" do
        o = self.instance_eval("@#{o}")
        expect(Flor.deep_get(o, k)).to eq([ b, v ])
      end
    end
  end

  describe '.deep_set' do

    it 'sets at the first level' do

      o = {}
      r = Flor.deep_set(o, 'a', 1)

      expect(o).to eq({ 'a' => 1 })
      expect(r).to eq(true)
    end
  end
end

