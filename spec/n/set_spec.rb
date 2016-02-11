
#
# specifying flor
#
# Tue Feb  2 16:33:43 JST 2016
#

require 'spec_helper'


describe 'Flor instructions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'set' do

    it 'has no effect on its own' do

      rad = %{
        sequence
          1
          set
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'ret' => 1 })
    end

    it 'sequences its children' do

      rad = %{
        set a
          0
          1
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'a' => 1, 'ret' => 1 })
    end

    it 'sets a field' do

      rad = %{
        set f.a: 1
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'a' => 1, 'ret' => 1 })
    end

    it 'sets a field, by default' do

      rad = %{
        set a: 2
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'a' => 2, 'ret' => 2 })
    end

    it 'sets a field, via an expanded key' do

      rad = %{
        set $(k): 3
      }

      r = @executor.launch(rad, payload: { 'k' => 'number' })

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'k' => 'number', 'number' => 3, 'ret' => 3 })
    end

    it 'sets a variable' do

      rad = %{
        sequence
          set v.a: 3
          push l $(v.a)
      }

      r = @executor.launch(rad, payload: {})

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'l' => [ 3 ], 'ret' => 3 })
    end

    it 'sets variables at various levels' do

      rad = %{
        sequence
          set v.a: 0
          push l '$(v.a) $(lv.a) $(gv.a)'
          sequence vars: {}
            set v.a: 1, lv.a: 2, gv.a: 3
            push l '$(v.a) $(lv.a) $(gv.a)'
          push l '$(v.a) $(lv.a) $(gv.a)'
      }

      r = @executor.launch(rad, payload: {})

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']['l']).to eq([ '0 0 0', '2 2 3', '3 3 3' ])
    end

    it 'evaluate a single child and use its ret as set value' do

      rad = %{
        sequence
          set v.a
            + 1 2 3
          push l $(v.a)
      }

      r = @executor.launch(rad, payload: {})

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'l' => [ 6 ], 'ret' => 6 })
    end

    it 'sets wars' do

      rad = %{
        sequence
          set w.a
            + 1 2
          push l $(w.a)
      }

      r = @executor.launch(rad, payload: {})

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'l' => [ 3 ], 'ret' => 3 })
    end

    it 'fails upon attempting to set a domain variable' do

      rad = %{
        set dv.a
          1
      }

      r = @executor.launch(rad, payload: {})

      expect(r['point']).to eq(
        'failed')
      expect(r['error']).to eq(
        { 'msg' => 'cannot set domain variables', 'kla' => 'IndexError' })
    end

    context 'splat' do

      it 'does not splat when there is only one target' do

        rad = %{
          set a
            [ 1, 2 ]
        }

        r = @executor.launch(rad, payload: {})

        expect(r['point']).to eq('terminated')
        expect(r['from']).to eq('0')
        expect(r['payload']).to eq({ 'a' => [ 1, 2 ], 'ret' => [ 1, 2 ] })
      end

      it 'does a, b = [ 3, 4 ]' do

        rad = %{
          set a, b
            [ 3, 4 ]
        }

        r = @executor.launch(rad, payload: {})

        expect(r['point']).to eq('terminated')
        expect(r['from']).to eq('0')
        expect(r['payload']).to eq({ 'a' => 3, 'b' => 4, 'ret' => [ 3, 4 ] })
      end

      it 'does a, b = [ 3, 4, 5 ]' do

        rad = %{
          set a, b
            [ 0, 1, 2 ]
        }

        r = @executor.launch(rad, payload: {})

        expect(r['point']).to eq('terminated')
        expect(r['from']).to eq('0')
        expect(r['payload']).to eq({ 'a' => 0, 'b' => 1, 'ret' => [ 0, 1, 2 ] })
      end

      it 'does a, *b = [ 3, 4, 5 ]'
      it 'does a, *b, c = [ 3, 4, 5, 6 ]'

      it "discards '_'"
    end
  end
end

