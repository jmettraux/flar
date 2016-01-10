
#
# specifying flor
#
# Sun Jan 10 12:26:14 JST 2016
#

require 'spec_helper'


describe 'Flor executions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  context 'with variables' do

    it 'expand the variables' do

      rad = %{
        $(a)
      }

      r = @executor.launch(rad, {}, { 'a' => 'A' })

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => 'A' })
    end
  end
end

