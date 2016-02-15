
#
# specifying flor
#
# Tue Feb  2 16:11:22 JST 2016
#

require 'spec_helper'


describe 'Flor executions' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'an instruction' do

    it 'expands $(stuff) when executed' do

      rad = %{
        push l $(f.a)
      }

      r = @executor.launch(rad, payload: { 'a' => 'A' })

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')
      expect(r['payload']['l']).to eq([ 'A' ])
    end
  end

  describe 'a dollar expression' do

    it 'might get expanded to a non-string value' do

      rad = %{
        sequence
          set v.a: { x: 0, y: 1 }
          push l $(f.stuff.msg)
          push l $(v.a)
          #push l f.stuff.msg
          #push l v.a
      }

      r = @executor.launch(
        rad,
        payload: { 'stuff' => { 'msg' => [ 'a', 'b', 'c' ] } })

      expect(r['point']).to eq('terminated')
      expect(r['from']).to eq('0')

      expect(
        r['payload']['l']
      ).to eq(
        [ [ 'a', 'b', 'c' ], { 'x' => 0, 'y' => 1 } ]
      )
    end
  end
end

__END__
  describe "$(exid)"
  {
    it "is expanded to the execution id"
    {
      exid = flon_generate_exid("z.dollar.exid");

      hlp_launch(
        exid,
        "trace $(exid)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      expect(fdja_ld(result, "payload.trace.0") ===f exid);
    }
  }

  describe "$(nid)"
  {
    it "is expanded to the node id"
    {
      exid = flon_generate_exid("z.dollar.nid");

      hlp_launch(
        exid,
        "sequence\n"
        "  trace $(nid)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      expect(fdja_ld(result, "payload.trace.0") ===f "0_0");
    }

    it "is expanded to the correct node id (subexecution)"
    {
      exid = flon_generate_exid("z.dollar.nid");

      hlp_launch(
        exid,
        "sequence\n"
        "  define sub\n"
        "    trace $(nid)\n"
        "  call sub\n"
        "  call sub\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      expect(fdja_ld(result, "payload.trace.0") ===f "0_0_0-1");
      expect(fdja_ld(result, "payload.trace.1") ===f "0_0_0-2");
    }

    it "is expanded as part of a string"
    {
      exid = flon_generate_exid("z.dollar.exid");

      hlp_launch(
        exid,
        "trace '$(colour) $(nid)'\n"
        "",
        "{ colour: '' }");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      expect(fdja_ls(result, "payload.trace.0") ===f ""
        " 0");
    }
  }

  describe "$(exnid) or $(enid)"
  {
    it "is expanded to execution id + node id"
    {
      exid = flon_generate_exid("z.dollar.exnid");

      hlp_launch(
        exid,
        "sequence\n"
        "  trace $(enid)\n"
        "  trace $(exnid)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      char *exnid0 = flu_sprintf("%s-0_0", exid);
      expect(fdja_ld(result, "payload.trace.0") ===F exnid0);

      char *exnid1 = flu_sprintf("%s-0_1", exid);
      expect(fdja_ld(result, "payload.trace.1") ===F exnid1);
    }
  }

  describe "$(domain)"
  {
    it "expands to the subdomain"
    {
      exid = flon_generate_exid("z.dollar.domain");

      hlp_launch(
        exid,
        "trace $(domain)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      expect(fdja_ld(result, "payload") ===f ""
        "{ trace: [ z.dollar.domain ] }");
    }
  }

  describe "$(domain+-x)"
  {
    it "expands to a subdomain"
    {
      exid = flon_generate_exid("z.dollar.domain.sub");

      hlp_launch(
        exid,
        "sequence\n"
        "  trace a $(domain+1)\n"
        "  trace b $(domain+2)\n"
        "  trace c $(domain-0)\n"
        "  trace d $(domain-1)\n"
        "  trace e $(domain-2)\n"
        "",
        "{}");

      result = hlp_wait(exid, "terminated", NULL, 3);

      expect(result != NULL); //fdja_putdc(result);

      expect(fdja_ld(result, "payload.trace") ===f ""
        "[ "
          "[ a, z ], "
          "[ b, z.dollar ], "
          "[ c, z.dollar.domain.sub ], "
          "[ d, z.dollar.domain ], "
          "[ e, z.dollar ] "
        "]");

