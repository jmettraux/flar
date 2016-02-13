
#
# specifying flor
#
# Sat Feb 13 09:49:20 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'define' do

    it 'sets the function in a variable' do

      rad = %{
        define sum a, b
          + a b
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')

      fun = r['vars']['sum']

      expect(fun['type']).to eq('function')
      expect(fun['tree'][0]).to eq('sequence')
      expect(fun['exid']).to match(/\Aeval-u0-/)
      expect(fun['vnid']).to eq('0')
    end
  end

  describe 'def' do

    it 'simply returns the function' do

      rad = %{
        def a, b
          + a b
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')

      fun = r['payload']['ret']

      expect(fun['type']).to eq('function')
      expect(fun['tree'][0]).to eq('sequence')
      expect(fun['exid']).to match(/\Aeval-u0-/)
      expect(fun['vnid']).to eq('0')
    end
  end
end

