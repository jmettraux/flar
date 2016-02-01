
#
# specifying flor
#
# Fri Jan 29 10:51:17 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::ThreadedExecutor.new
  end

  after :each do

    @executor.stop
  end

  describe 'wait' do

    it 'returns 0 if empty' do

      rad = %{
        wait 2s
      }

      w = @executor.launch(rad)

      t0 = Time.now

      r = w.wait('terminated')

      t1 = Time.now

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => 0 })
    end
  end
end

