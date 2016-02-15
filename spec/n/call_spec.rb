
#
# specifying flor
#
# Sat Feb 13 16:26:52 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'call' do

    it 'fails if the function is unknown' do

      rad = %{
        call nada
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq('no function named "nada"')
    end

    it 'calls a function' do

      rad = %{
        sequence
          define push1
            push l 1
          call push1
          call push1
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'l' => [ 1, 1 ], 'ret' => 1 })
    end

    it 'wraps the function body in a sequence' do

      rad = %{
        sequence
          define push01
            push l 0
            push l 1
          call push01
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'l' => [ 0, 1 ], 'ret' => 1 })
    end

    it 'calls a function with arguments' do

      rad = %{
        sequence
          define sum a, b
            + $(a) $(b)
          call sum 1, 2
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => 3 })
    end
  end
end

