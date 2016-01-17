
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
          [ '>', {}, 2, [
            [ 'a', {}, 2, [] ],
            [ 'b', {}, 2, [] ]
          ] ]
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
          [ '>', {}, 2, [
            [ 'a', {}, 2, [] ],
            [ 'b', {}, 2, [] ]
          ] ]
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
          [ '>', {}, 2, [
            [ 'a', { '_0' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 2, [] ]
          ] ]
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
          [ 'or', {}, 2, [
            [ 'a', {}, 2, [] ],
            [ 'b', {}, 2, [] ],
            [ 'c', {}, 2, [] ]
          ] ]
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
          [ 'or', {}, 2, [
            [ 'a', {}, 2, [] ],
            [ 'b', { '_0' => 'and', '_1' => 'c' }, 2, [] ]
          ] ]
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
          [ 'and', {}, 2, [
            [ 'a', {}, 2, [] ],
            [ 'b', { '_0' => 'or', '_1' => 'c' }, 2, [] ]
          ] ]
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
          [ 'and', {}, 2, [
            [ 'a', { '_0' => 'or', '_1' => 'b' }, 2, [] ],
            [ 'c', {}, 2, [] ]
          ] ]
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
          [ 'or', {}, 2, [
            [ 'trace',
              { '_0' => 'a' }, 2, [] ],
            [ 'trace',
              { '_0' => 'b', '_1' => 'or', '_2' => 'trace', '_3' => 'c' }, 2, [] ]
          ] ]
        )
      end
    end

    context '$(cmp):' do

      it 'rewrites  $(cmp) x y' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            $(cmp) x y
          },
          payload: { 'cmp' => '>' })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ '>', {}, 2, [
            [ 'x', {}, 2, [] ],
            [ 'y', {}, 2, [] ]
          ] ]
        )
      end

      it 'rewrites  x $(cmp) y' do

        executor, node, message =
          RewriteExecutor.prepare(%{
            x $(cmp) y
          },
          payload: { 'cmp' => '>' })

        executor.rewrite_tree(node, message)

        expect(node['inst']).to eq('>')

        expect(node['tree']).to eq(
          [ '>', {}, 2, [
            [ 'x', {}, 2, [] ],
            [ 'y', {}, 2, [] ]
          ] ]
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
          [ 'if', {}, 2, [
            [ 'a', {}, 2, [] ]
          ] ]
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
          [ 'unless', {}, 2, [
            [ 'a', {}, 2, [] ]
          ] ]
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
          [ 'if', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ]
          ] ]
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
          [ 'if', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 3, [] ]
          ] ]
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
          [ 'if', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', {}, 3, [] ],
            [ 'd', {}, 4, [] ]
          ] ]
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
          [ 'if', {}, 2, [
            [ 'val', { '_0' => true }, 2, [] ]
          ] ]
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
          [ 'elif', {}, 2, [
            [ 'val', { '_0' => true }, 2, [] ]
          ] ]
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
          [ 'elsif', {}, 2, [
            [ 'val', { '_0' => true }, 2, [] ]
          ] ]
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
          [ 'ife', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 2, [] ]
          ] ]
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
          [ 'ife', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 2, [] ],
            [ 'e', { '_0' => 'f' }, 2, [] ]
          ] ]
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
          [ 'elsif', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 2, [] ]
          ] ]
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
          [ 'elsif', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 2, [] ]
          ] ]
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
          [ 'ife', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', { '_0' => 'd' }, 2, [] ]
          ] ]
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
          [ 'ife', {}, 2, [
            [ 'a', { '_0' => '>', '_1' => 'b' }, 2, [] ],
            [ 'c', {}, 2, [
              [ 'e', { '_0' => 'f' }, 3, [] ],
              [ 'g', { '_0' => 'h' }, 4, [] ]
            ] ]
          ] ]
        )
      end
    end
  end
end

__END__
      it "rewrites  c d unless a > b"
      {
        msg = mrad(
          "c d unless a > b\n"
        );
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ unlesse, {}, 1, [ "
            "[ a, { _0: >, _1: b }, 1, [] ], "
            "[ c, { _0: d }, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "unlesse");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }
    }

