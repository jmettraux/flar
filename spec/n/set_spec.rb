
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

    it 'splats arrays when setting'
      #
      # set a, b, c
      #   [ 1, 2, 3 ]

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
  end
end

__END__
    it "cannot set domain vars"
    {
      exid = flon_generate_exid("n.test.set.cannot");

      hlp_launch(
        exid,
        "sequence\n"
        "  trace $(v.city)\n"
        "  set d.city: Brussels\n"
        "  trace $(v.city)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_ld(result, "payload") ===f ""
        "{ trace: [ Birmingham, Birmingham ], ret: Brussels }");
    }
  }
