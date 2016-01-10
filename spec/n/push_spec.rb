
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

  describe 'push' do

    it 'pushes to a field' do

      rad = %{
        push l 1
      }

      r = @executor.launch(rad, { 'l' => [ 0 ] }, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'l' => [ 0, 1 ] })
    end

    it 'creates a new array if necessary' do

      rad = %{
        push l 1
      }

      r = @executor.launch(rad, {}, {})

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'l' => [ 1 ] })
    end

    it 'fails if the target is not an array' do

      rad = %{
        push l 1
      }

      r = @executor.launch(rad, { 'l' => 0 }, {})

      expect(r['point']).to eq('failed')
      expect(r['error']['text']).to eq('target value is not an array')
    end

    it 'pushes $(ret) when no attributes'
  end
end

