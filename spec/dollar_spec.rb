
#
# specifying flor
#
# Sat Dec 12 07:05:15 JST 2015
#

require 'spec_helper'


class SpecDollar < Flor::Dollar

  def initialize

    @h = {
      'brown' => 'fox',
      'lazy' => 'dog',
      'quick' => 'jump',
      'l' => 'la',
      'z' => 'zy',
      'black' => 'PuG',
      'func' => 'u',
      'ba' => 'black adder',
      'bs' => 'bLACK shEEp',
      'msg' => '"hello world"',
      'msg1' => 'hello "le monde"' }
  end

  def lookup(k)

    @h[k]
  end
end


describe Flor::Dollar do

  describe '#expand' do

    before :each do

      @d = SpecDollar.new
    end

    it 'does not expand if not necessary' do

      expect(
        @d.expand('quick brown fox')
      ).to eq(
        'quick brown fox'
      )
    end

    it 'expands "$(brown)"' do

      expect(
        @d.expand('$(brown)')
      ).to eq(
        'fox'
      )
    end

    it 'expands ".$(brown)."' do

      expect(
        @d.expand('.$(brown).')
      ).to eq(
        '.fox.'
      )
    end

    it 'expands "$(brown) $(lazy)"' do

      expect(
        @d.expand('$(brown) $(lazy)')
      ).to eq(
        'fox dog'
      )
    end

    it 'expands "$($(l)$(z))"' do

      expect(
        @d.expand('$($(l)$(z))')
      ).to eq(
        'dog'
      )
    end

    it "expands to a blank string if it doesn't find" do

      expect(
        @d.expand('<$(blue)>')
      ).to eq(
        '<>'
      )
    end

    it "doesn't expand \"a)b\"" do

      expect(@d.expand('a)b')).to eq('a)b')
    end

    it "doesn't expand \"$xxx\"" do

      expect(@d.expand('$xxx')).to eq('$xxx')
    end

    it "doesn't expand \"x$xxx\"" do

      expect(@d.expand('x$xxx')).to eq('x$xxx')
    end

    it "doesn't expand \"$(nada||'$xxx)\""
    #
    #  expect(@d.expand("$(nada||'$xxx)")).to eq('$xxx')
    #end

    it "accepts an escaped )"
    #{
    #  expect(fdol_expand("$(nada||'su\\)rf)", d, fdol_dlup) ===f ""
    #    "su)rf");
    #}
    it "accepts an escaped ) (deeper)"
    #{
    #  expect(fdol_expand("$(a||'$(nada||'su\\)rf))", d, fdol_dlup) ===f ""
    #    "su)rf");
    #}
    it "accepts an escaped $"
    # ...
  end
end

