
#
# specifying flor
#
# Sun Feb  7 14:27:04 JST 2016
#

require 'spec_helper'


describe Flor do

  describe '.deep_get' do

    it 'returns success, value' do

      expect(
        Flor.deep_get({}, 'a')
      ).to eq(
        [ false, nil ]
      )
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

