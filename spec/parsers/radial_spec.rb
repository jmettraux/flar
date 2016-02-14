
#
# specifying flor
#
# Sat Dec 26 10:37:45 JST 2015
#

require 'spec_helper'


def determine_title(radial, tree, line)

  title =
    radial.length > 31 ?
    "#{(radial[0, 31] + '...').inspect} l#{line}" :
    "#{radial.inspect} l#{line}"
  title =
    tree == nil ?
    "doesn't parse #{title}" :
    "parses #{title}"

  title
end

describe Flor::Radial do

  describe '.parse' do

    it 'tracks the origin of the string' do

      expect(
        Flor::Radial.parse('sequence timeout: 1d', 'var/lib/one.rad')
      ).to eq(
        [ 'y_sequence', { 'y_timeout' => 'y_1d' }, 1, [], 'var/lib/one.rad' ]
      )
    end

    context 'core' do

      pe = lambda { |x| parse_expectation.call(x) }

      [
        [ '12[3', nil, __LINE__ ],

        [ 'sequence',
          [ 'y_sequence', {}, 1, [] ],
          __LINE__ ],

        [ "sequence\n" +
          "  participant 'bravo'",
          [ 'y_sequence', {}, 1, [
            [ 'y_participant', { '_0' => 's_bravo' }, 2, [] ]
          ] ],
          __LINE__ ],

        [
          "sequence\n" +
          "  participant 'alpha'\n" +
          "  concurrence\n" +
          "    participant 'bravo'\n" +
          "    participant 'charly'\n" +
          "  participant 'delta'",
          [ 'y_sequence', {}, 1, [
            [ 'y_participant', { '_0' => 's_alpha' }, 2, [] ],
            [ 'y_concurrence', {}, 3, [
              [ 'y_participant', { '_0' => 's_bravo' }, 4, [] ],
              [ 'y_participant', { '_0' => 's_charly' }, 5, [] ]
            ] ],
            [ 'y_participant', { '_0' => 's_delta' }, 6, [] ]
          ] ],
          __LINE__ ],

        [
          "iterate [\n" +
          "  1 2 3 ]\n" +
          "  bravo",
          [ 'y_iterate', { '_0' => [ 1, 2, 3 ] }, 1, [
            [ 'y_bravo', {}, 3, [] ]
          ] ],
          __LINE__ ],

        [
          "participant charly a: 0, b: one c: true, d: [ four ]",
          [ 'y_participant', {
            '_0' => 'y_charly',
            'y_a' => 0, 'y_b' => 'y_one', 'y_c' => true, 'y_d' => [ 'y_four' ]
          }, 1, [] ],
          __LINE__ ],

        [
          "participant charly,\n" +
          "  aa: 0,\n" +
          "  bb: one,\n" +
          "  cc: true,\n" +
          "  dd: [ four ]",
          [ 'y_participant', {
            '_0' => 'y_charly',
            'y_aa' => 0, 'y_bb' => 'y_one', 'y_cc' => true, 'y_dd' => [ 'y_four' ]
          }, 1, [] ],
          __LINE__ ],

        [
          "participant charly, # charlie\n" +
          "  aa: 0, # zero\n" +
          "  bb: one, # one\n" +
          "  cc: true, # three\n" +
          "  dd: [ four ] # four",
          [ 'y_participant', {
            '_0' => 'y_charly',
            'y_aa' => 0, 'y_bb' => 'y_one', 'y_cc' => true, 'y_dd' => [ 'y_four' ]
          }, 1, [] ],
          __LINE__ ],

        [
          "participant charly, # charlie\n" +
          "  aa:     # zero\n" +
          "    0,    // zero indeed\n" +
          "  bb: one # one\n",
          [ 'y_participant', {
            '_0' => 'y_charly', 'y_aa' => 0, 'y_bb' => 'y_one'
          }, 1, [] ],
          __LINE__ ],

        [
          "nada aa bb d: 2, e: 3",
          [ 'y_nada', { '_0' => 'y_aa', '_1' => 'y_bb', 'y_d' => 2, 'y_e' => 3 }, 1, [] ],
          __LINE__ ],

        [
          "nada d: 0 e: 1 aa bb",
          [ 'y_nada', { 'y_d' => 0, 'y_e' => 1, '_2' => 'y_aa', '_3' => 'y_bb' }, 1, [] ],
          __LINE__ ],

        [
          "sequence\n" +
          "  participant toto # this\n" +
          "  participant tutu # that",
          [ 'y_sequence', {}, 1, [
            [ 'y_participant', { '_0' => 'y_toto' }, 2, [] ],
            [ 'y_participant', { '_0' => 'y_tutu' }, 3, [] ]
          ] ],
          __LINE__ ],

        [
          "# Tue Jul  8 05:50:28 JST 2014\n" +
          "sequence\n" +
          "  participant toto",
          [ 'y_sequence', {}, 2, [
            [ 'y_participant', { '_0' => 'y_toto' }, 3, [] ]
          ] ],
          __LINE__ ],

        [
          "sequence\n" +
          "  git://github.com/flon-io/tst x b: 0\n",
          #"  git://github.com/flon-io/tst x y a: 0, b: 1\n",
          #"  git://github.com/flon-io/tst a: 0, b: 1\n",
          [ 'y_sequence', {}, 1, [
            [ 'y_git://github.com/flon-io/tst', { '_0' => 'y_x', 'y_b' => 0 }, 2, [] ]
          ] ],
          __LINE__ ],

        [
          "$(a)\n" +
          "  b $(c) $(d): e f: $(g) $(h)$(i)\n",
          [ 'y_$(a)', {}, 1, [
            [ 'y_b', {
              '_0' => 'y_$(c)', 'y_$(d)' => 'y_e', 'y_f' => 'y_$(g)', '_3' => 'y_$(h)$(i)'
            }, 2, [] ]
          ] ],
          __LINE__ ],

        [
          "invoke a b: c:y\n",
          [ 'y_invoke', { '_0' => 'y_a', 'y_b' => 'y_c:y' }, 1, [] ],
          __LINE__ ],

        [
          "sequence\n" +
          "  + a b \n" +
          "  - a b \n" +
          "  a + b\n" +
          "  a - b\n" +
          "  * c d\n" +
          "  / c d\n" +
          "  c * d\n" +
          "  c / d\n",
          [ 'y_sequence', {}, 1, [
            [ 'y_+', { '_0' => 'y_a', '_1' => 'y_b' }, 2, [] ],
            [ 'y_-', { '_0' => 'y_a', '_1' => 'y_b' }, 3, [] ],
            [ 'y_a', { '_0' => 'y_+', '_1' => 'y_b' }, 4, [] ],
            [ 'y_a', { '_0' => 'y_-', '_1' => 'y_b' }, 5, [] ],
            [ 'y_*', { '_0' => 'y_c', '_1' => 'y_d' }, 6, [] ],
            [ 'y_/', { '_0' => 'y_c', '_1' => 'y_d' }, 7, [] ],
            [ 'y_c', { '_0' => 'y_*', '_1' => 'y_d' }, 8, [] ],
            [ 'y_c', { '_0' => 'y_/', '_1' => 'y_d' }, 9, [] ]
          ] ],
          __LINE__ ],

        [
          "=~\n" +
          "  toto\n" +
          "  to$\n",
          [ 'y_=~', {}, 1, [
            [ 'y_toto', {}, 2, [] ],
            [ 'y_to$', {}, 3, [] ]
          ] ],
          __LINE__ ],

        [
          "sequence\n" +
          "  3\n" +
          "  null\n" +
          "  quatre\n",
          [ 'y_sequence', {}, 1, [
            [ 'y_val', { '_0' => 3 }, 2, [] ],
            [ 'y_val', { '_0' => nil }, 3, [] ],
            [ 'y_quatre', {}, 4, [] ]
          ] ],
          __LINE__ ],

        [
          "set f.a: 1",
          [ 'y_set', { 'y_f.a' => 1 }, 1, [] ],
          __LINE__ ]

      ].each do |radial, tree, line|

        it(determine_title(radial, tree, line)) do
          expect(Flor::Radial.parse(radial)).to eq(tree)
        end
      end
    end

    context 'parenthesis' do

      [
        [
          "if (a > b)\n",
          [ 'y_if', {
            '_0' => [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 1, [] ]
          }, 1, [] ],
          __LINE__ ],

        [
          "(a > 0) and (b > 1)\n",
          [
            [ 'y_a', { '_0' => 'y_>', '_1' => 0 }, 1, [] ],
            { '_0' => 'y_and',
              '_1' => [ 'y_b', { '_0' => 'y_>', '_1' => 1 }, 1, [] ] },
            1,
            []
          ],
          __LINE__ ],

        [
          "if (a > $(b)$(c))\n",
          [ 'y_if', {
            '_0' => [ 'y_a', { '_0' => 'y_>', '_1' => "y_$(b)$(c)" }, 1, [] ]
          }, 1, [] ],
          __LINE__ ],

        [
          "if ( # really?\n" +
          "  a > b)\n",
          [ 'y_if', {
            '_0' => [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ]
          }, 1, [] ],
          __LINE__ ],

        [
          "if ( // really?\n" +
          "   a > b)\n",
          [ 'y_if', {
            '_0' => [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ]
          }, 1, [] ],
          __LINE__ ],

        [
          "task Alan value: (1 + 2)",
          [ 'y_task', {
            '_0' => 'y_Alan',
            'y_value' => [
              [ 'y_val', { '_0'=>1 }, 1, [] ],
              { '_0' => 'y_+', '_1' => 2 }, 1, [] ]
            }, 1, [] ],
          __LINE__ ],

        [
          "sub (1 + 2)",
          [ 'y_sub', {
            '_0' => [
              [ 'y_val', { '_0' => 1 }, 1, [] ], { '_0' => 'y_+', '_1' => 2 }, 1, []
            ]
          }, 1, [] ],
          __LINE__ ]

      ].each do |radial, tree, line|

        it(determine_title(radial, tree, line)) do
          expect(Flor::Radial.parse(radial)).to eq(tree)
        end
      end
    end

    context 'regexes' do

      [
        [
          "sequence\n" +
          "  =~ ab /c d/\n",
          [ 'y_sequence', {}, 1, [
            [ 'y_=~', { '_0' => 'y_ab', '_1' => "r_/c d/" }, 2, [] ]
          ] ],
          __LINE__ ],

        [
          "sequence\n" +
          "  =~ ab /c, d/i\n",
          [ 'y_sequence', {}, 1, [
            [ 'y_=~', { '_0' => 'y_ab', '_1' => "r_/c, d/i" }, 2, [] ]
          ] ],
          __LINE__ ]

      ].each do |radial, tree, line|

        it(determine_title(radial, tree, line)) do
          expect(Flor::Radial.parse(radial)).to eq(tree)
        end
      end
    end
  end
end

