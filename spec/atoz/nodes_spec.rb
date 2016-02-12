
#
# specifying flor
#
# Fri Feb 12 10:46:25 JST 2016
#

require 'spec_helper'


describe 'Flor execution' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'nodes' do

    it 'get cleaned up after use' do

      rad = %{
        sequence
          set v.a: 0
      }

      r = @executor.launch(rad)
      #pp r

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 0 })
      expect(r['vars']).to eq({ 'a' => 0 })

      #pp @executor.execution
      expect(@executor.execution['errors']).to eq([])
      expect(@executor.execution['nodes']).to eq({})
    end
  end
end

