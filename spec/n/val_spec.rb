
#
# specifying flor
#
# Thu Jan  7 06:22:04 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @interpreter = Flor::TransientInterpreter.new
  end

  describe 'val' do

    it 'returns values on their own' do

      rad = %{
        2
      }

      r = @interpreter.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      #expect(r['exid']).to eq(exid)
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => 2 })
    end
  end
end

