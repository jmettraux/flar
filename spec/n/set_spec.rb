
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

    it 'sets a field' do

      rad = %{
        set f.a: 1
      }

      r = @executor.launch(rad)

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']).to eq({ 'a' => 1, 'ret' => 1 })
    end
  end
end

__END__
  describe "set"
  {
    it "sets a field"
    {
      exid = flon_generate_exid("n.set.fld");

      hlp_launch(
        exid,
        "set f.a: 1\n"
        "",
        "{ hello: set }");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_lj(result, "payload") ===F fdja_vj(""
        "{ hello: set, ret: 1, a: 1 }"));
    }

    it "sets a field, by default"
    {
      exid = flon_generate_exid("n.set.fld.default");

      hlp_launch(
        exid,
        "set a: 2\n"
        "",
        "{ hello: set }");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_lj(result, "payload") ===F fdja_vj(""
        "{ hello: set, ret: 2, a: 2 }"));
    }

    it "sets a field, via an expanded key"
    {
      exid = flon_generate_exid("n.set.fld.expankey");

      hlp_launch(
        exid,
        "set $(k): 3\n"
        "",
        "{ k: number }");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_lj(result, "payload") ===F fdja_vj(""
        "{ k: number, ret: 3, number: 3 }"));
    }

    it "sets a variable"
    {
      exid = flon_generate_exid("n.set.var");

      hlp_launch(
        exid,
        "sequence\n"
        "  set v.a: 3\n"
        "  trace $(v.a)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_ld(result, "payload") ===f ""
        "{ ret: 3, trace: [ 3 ] }");
    }

    it "sets variables at various levels"
    {
      exid = flon_generate_exid("n.set.var.levels");

      hlp_launch(
        exid,
        "sequence\n"
        "  set v.a: 0\n"
        "  trace '$(v.a) $(lv.a) $(gv.a)'\n"
        "  sequence vars: {}\n"
        "    set v.a: 1, lv.a: 2, gv.a: 3\n"
        "    trace '$(v.a) $(lv.a) $(gv.a)'\n"
        "  trace '$(v.a) $(lv.a) $(gv.a)'\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_ld(result, "payload") ===f ""
        "{ ret: 3, trace: [ \"0 0 0\", \"2 2 3\", \"3 3 3\" ] }");
    }

    it "evaluate a single child and use its ret as set value"
    {
      exid = flon_generate_exid("n.set.child");

      hlp_launch(
        exid,
        "sequence\n"
        "  set v.a\n"
        "    + 1 2 3\n"
        "  trace $(v.a)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_ld(result, "payload") ===f ""
        "{ ret: 6, trace: [ 6 ] }");
    }

    it "sets wars"
    {
      exid = flon_generate_exid("n.set.wars");

      hlp_launch(
        exid,
        "sequence\n"
        "  set w.a\n"
        "    + 1 2\n"
        "  trace $(w.a)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL);
      //flu_putf(fdja_todc(result));

      expect(fdja_ld(result, "payload") ===f ""
        "{ ret: 3, trace: [ 3 ] }");
    }

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
