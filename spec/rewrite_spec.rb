
#
# specifying flor
#
# Wed Jan 13 22:08:45 JST 2016
#

require 'spec_helper'


# An executor just for testing Executor#rewrite_tree
#
class RewriteExecutor < Flor::TransientExecutor

  public :rewrite_tree

  def self.prepare(tree, opts={})

    executor = self.new

    now = Flor.tstamp

    root = {
      'nid' => '0',
      'parent' => nil,
      'vars' => opts[:vars] || opts['vars'],
      'ctime' => now,
      'mtime' => now }
    executor.execution['nodes']['0'] = root

    now = Flor.tstamp

    node = {
      'nid' => '0_0',
      'parent' => '0',
      'ctime' => now,
      'mtime' => now }
    executor.execution['nodes']['0_0'] = node

    tree =
      tree.is_a?(String) ? Flor::Radial.parse(tree) : tree
    tree << 'sx' # the "filename"

    message = {
      'point' => 'execute',
      'tree' => tree = tree.is_a?(String) ? Flor::Radial.parse(tree) : tree,
      'payload' => opts[:payload] || opts['payload'] || {} }

    [ executor, node, message ]
  end
end


describe Flor::Executor do

  describe '#rewrite_tree' do

    it "doesn't set 'tree' when there is no rewrite" do

      executor, node, message =
        RewriteExecutor.prepare(%{
          >
            a
            b
        })

      executor.rewrite_tree(node, message)

      expect(node['inst']).to eq('>')
      expect(node['tree']).to eq(nil)
    end

    context "'>'" do

      it 'rewrites  a > b' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            a > b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ 'y_>', {}, 2, [
            [ 'y_a', {}, 2, [] ],
            [ 'y_b', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  > a b' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            > a b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ 'y_>', {}, 2, [
            [ 'y_a', {}, 2, [] ],
            [ 'y_b', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  a b > c d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            a b > c d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ 'y_>', {}, 2, [
            [ 'y_a', { '_0' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context "'and', 'or':" do

      it 'rewrites  a or b or c' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            a or b or c
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('or')

        expect(node['tree']).to eq(
          [ 'y_or', {}, 2, [
            [ 'y_a', {}, 2, [] ],
            [ 'y_b', {}, 2, [] ],
            [ 'y_c', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  a or b and c' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            a or b and c
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('or')

        expect(node['tree']).to eq(
          [ 'y_or', {}, 2, [
            [ 'y_a', {}, 2, [] ],
            [ 'y_b', { '_0' => 'y_and', '_1' => 'y_c' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  a and (b or c)' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            a and (b or c)
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('and')

        expect(node['tree']).to eq(
          [ 'y_and', {}, 2, [
            [ 'y_a', {}, 2, [] ],
            [ 'y_b', { '_0' => 'y_or', '_1' => 'y_c' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  (a or b) and c' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            (a or b) and c
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('and')

        expect(node['tree']).to eq(
          [ 'y_and', {}, 2, [
            [ 'y_a', { '_0' => 'y_or', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  trace a or (trace b or trace c)' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            trace a or (trace b or trace c)
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('or')

        expect(node['tree']).to eq(
          [ 'y_or', {}, 2, [
            [ 'y_trace',
              { '_0' => 'y_a' }, 2, [] ],
            [ 'y_trace',
              { '_0' => 'y_b', '_1' => 'y_or', '_2' => 'y_trace', '_3' => 'y_c' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context '$(cmp):' do

      it 'rewrites  $(cmp) x y' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            $(f.cmp) x y
          },
          payload: { 'cmp' => '>' })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ 's_>', {}, 2, [
            [ 'y_x', {}, 2, [] ],
            [ 'y_y', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  x $(cmp) y' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            x $(f.cmp) y
          },
          payload: { 'cmp' => '>' })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ 's_>', {}, 2, [
            [ 'y_x', {}, 2, [] ],
            [ 'y_y', {}, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context "head 'if':" do

      it 'rewrites  if a' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if a
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('if')

        expect(node['tree']).to eq(
          [ 'y_if', {}, 2, [
            [ 'y_a', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  unless a' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            unless a
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('unless')

        expect(node['tree']).to eq(
          [ 'y_unless', {}, 2, [
            [ 'y_a', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  if a > b' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if a > b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('if')

        expect(node['tree']).to eq(
          [ 'y_if', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  if a > b \ c d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if a > b
              c d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('if')

        expect(node['tree']).to eq(
          [ 'y_if', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 3, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  if a > b \ c \ d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if a > b
              c
              d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('if')

        expect(node['tree']).to eq(
          [ 'y_if', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', {}, 3, [] ],
            [ 'y_d', {}, 4, [] ]
          ], 'sx' ]
        )
      end

      it "doesn't rewrite  if \ a > b" do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if
              a > b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('if')

        expect(node['tree']).to eq(nil)
      end

      it 'rewrites  if true' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if true
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('if')

        expect(node['tree']).to eq(
          [ 'y_if', {}, 2, [
            [ 'y_val', { '_0' => true }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  elif true' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            elif true
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('elif')

        expect(node['tree']).to eq(
          [ 'y_elif', {}, 2, [
            [ 'y_val', { '_0' => true }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  elsif true' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            elsif true
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('elsif')

        expect(node['tree']).to eq(
          [ 'y_elsif', {}, 2, [
            [ 'y_val', { '_0' => true }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context 'then:' do

      it 'rewrites  if a > b then c d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if a > b then c d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('ife')

        expect(node['tree']).to eq(
          [ 'y_ife', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  if a > b then c d else e f' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            if a > b then c d else e f
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('ife')

        expect(node['tree']).to eq(
          [ 'y_ife', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ],
            [ 'y_e', { '_0' => 'y_f' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  elsif a > b then c d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            elsif a > b then c d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('elsif')

        expect(node['tree']).to eq(
          [ 'y_elsif', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  else if a > b then c d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            else if a > b then c d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('elsif')

        expect(node['tree']).to eq(
          [ 'y_elsif', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context "tail 'if':" do

      it 'rewrites  c d if a > b' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            c d if a > b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('ife')

        expect(node['tree']).to eq(
          [ 'y_ife', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  c if a > b \ e f \ g h' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            c if a > b
              e f
              g h
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('ife')

        expect(node['tree']).to eq(
          [ 'y_ife', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', {}, 2, [
              [ 'y_e', { '_0' => 'y_f' }, 3, [] ],
              [ 'y_g', { '_0' => 'y_h' }, 4, [] ]
            ] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  c d unless a > b' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            c d unless a > b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('unlesse')

        expect(node['tree']).to eq(
          [ 'y_unlesse', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ],
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context "'else if':" do

      it 'rewrites  else if a > b' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            else if a > b
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('elsif')

        expect(node['tree']).to eq(
          [ 'y_elsif', {}, 2, [
            [ 'y_a', { '_0' => 'y_>', '_1' => 'y_b' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context "'else':" do

      it 'rewrites  else c d' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            else c d
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('else')

        expect(node['tree']).to eq(
          [ 'y_else', {}, 2, [
            [ 'y_c', { '_0' => 'y_d' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context "'set':" do

      it "doesn't rewrite  set" do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('set')

        expect(node['tree']).to eq(nil)
      end

      it "doesn't rewrite  set k" do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set k
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('set')

        expect(node['tree']).to eq(nil)
      end

      it 'rewrites  set k: v' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set k: v
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('set')

        expect(node['tree']).to eq(
          [ 'y_set', { '_0' => 'y_k' }, 2, [
            [ 'y_v', {}, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  set k0: v0, k1: v1' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set k0: v0, k1: v1
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('sequence')

        expect(node['tree']).to eq(
          [ 'y_sequence', {}, 2, [
            [ 'y_set', { '_0' => 'y_k0' }, 2, [
              [ 'y_v0', {}, 2, [] ]
            ] ],
            [ 'y_set', { '_0' => 'y_k1' }, 2, [
              [ 'y_v1', {}, 2, [] ]
            ] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  set k0: v0, k1: (a + 1), k2: v2' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set k0: v0, k1: (a + 1), k2: v2
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('sequence')

        expect(node['tree']).to eq(
          [ 'y_sequence', {}, 2, [
            [ 'y_set', { '_0' => 'y_k0' }, 2, [
              [ 'y_v0', {}, 2, [] ]
            ] ],
            [ 'y_set', { '_0' => 'y_k1' }, 2, [
              [ 'y_a', { '_0' => 'y_+', '_1' => 1 }, 2, [] ]
            ] ],
            [ 'y_set', { '_0' => 'y_k2' }, 2, [
              [ 'y_v2', {}, 2, [] ]
            ] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  set k: 1' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set k: 1
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('set')

        expect(node['tree']).to eq(
          [ 'y_set', { '_0' => 'y_k' }, 2, [
            [ 'y_val', { '_0' => 1 }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  set k: blue' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            set k: blue
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('set')

        expect(node['tree']).to eq(
          [ 'y_set', { '_0' => 'y_k' }, 2, [
            [ 'y_blue', {}, 2, [] ]
          ], 'sx' ]
        )
      end
    end

    context '():' do

      it 'rewrites  task bob count: (+ 1 2)' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            task bob count: (+ 1 2)
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('sequence')

        expect(node['tree']).to eq(
          [ 'y_sequence', {}, 2, [
            [ 'y_set', { '_0' => 'y_w._0' }, 2, [
              [ 'y_+', { '_0' => 1, '_1' => 2 }, 2, [] ]
            ] ],
            [ 'y_task', { '_0' => 'y_bob', 'y_count' => 'y_w._0' }, 2, [] ]
          ], 'sx' ]
        )
      end

      it 'rewrites  sub (1 + 2)' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            sub (1 + 2)
          })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('sequence')

        expect(node['tree']).to eq(
          [ 'y_sequence', {}, 2, [
            [ 'y_set', { '_0' => 'y_w._0' }, 2, [
              [ [ 'y_val', { '_0' => 1 }, 2, [] ],
                { '_0' => 'y_+', '_1' => 2 }, 2, [] ]
            ] ],
            [ 'y_sub', { '_0' => 'y_w._0' }, 2, [] ]
          ], 'sx' ]
        )
      end
    end
  end
end

