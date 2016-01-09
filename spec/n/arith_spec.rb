
#
# specifying flor
#
# Sat Jan  9 17:33:25 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  describe '+' do

    it 'returns 0 if empty' do

      rad = %{
        +
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 0 })
    end

    it 'adds two numbers' do

      rad = %{
        +
          1
          2
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 3 })
    end

    it 'adds three numbers' do

      rad = %{
        +
          3
          2
          -1
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 4 })
    end
  end

  describe '*' do

    it 'returns 0 if empty' do

      rad = %{
        *
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 0 })
    end

    it 'multiplies three numbers' do

      rad = %{
        *
          3
          2
          -1
      }

      r = Flor.eval(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => -6 })
    end
  end
end

