
#
# specifying flor
#
# Fri Jan 29 10:51:17 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'wait' do

    it 'returns 0 if empty' do

      rad = %{
        wait 2s
      }

      r = @executor.launch(rad, nowait: true)

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 0 })
    end
  end
end

