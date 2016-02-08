
#
# specifying flor
#
# Mon Feb  8 14:53:55 JST 2016
#

require 'spec_helper'


describe 'Flor executions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'an invalid radial composition' do

    it 'gets rejected' do

      rad = %{
        "pure\n"
        "  nada\n"
      }

      expect {
        @executor.launch(rad, payload: { 'a' => 'A' })
      }.to raise_error(ArgumentError, 'radial parse failure')
    end
  end
end

