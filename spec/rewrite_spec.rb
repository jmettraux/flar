
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
    end
  end
end

__END__
      it "rewrites  if a"
      {
        msg = mrad("if a");
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ if, {}, 1, [ "
            "[ a, {}, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "if");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "rewrites  unless a"
      {
        msg = mrad("unless a");
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ unless, {}, 1, [ "
            "[ a, {}, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "unless");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "rewrites  if a > b"
      {
        msg = mrad("if a > b");
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ if, {}, 1, [ "
            "[ a, { _0: >, _1: b }, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "if");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "rewrites  if a > b \\ c d"
      {
        msg = mrad(
          "if a > b\n"
          "  c d"
        );
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ if, {}, 1, [ "
            "[ a, { _0: >, _1: b }, 1, [] ], "
            "[ c, { _0: d }, 2, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "if");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "doesn't rewrite  if \\ a > b"
      {
        msg = mrad(
          "if \n"
          "  a > b\n"
          "  c d\n"
        );
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ if, {}, 1, [ "
            "[ a, { _0: >, _1: b }, 2, [] ], "
            "[ c, { _0: d }, 3, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "if");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "rewrites  if true"
      {
        msg = mrad(
          "if true\n"
        );
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ if, {}, 1, [ "
            "[ val, { _0: true }, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "if");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "rewrites  elif true"
      {
        msg = mrad(
          "elif true\n"
        );
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ elif, {}, 1, [ "
            "[ val, { _0: true }, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "elif");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      it "rewrites  elsif true"
      {
        msg = mrad(
          "elsif true\n"
        );
        //fdja_putdc(fdja_l(msg, "tree"));

        flon_rewrite_tree(node, msg);

        expect(fdja_ld(msg, "tree") ===f ""
          "[ elsif, {}, 1, [ "
            "[ val, { _0: true }, 1, [] ] "
          "], sx ]");

        expect(fdja_ls(node, "inst", NULL) ===f "elsif");
        expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
      }

      context "then:"
      {
        it "rewrites  if a > b then c d"
        {
          msg = mrad(
            "if a > b then c d\n"
          );
          //fdja_putdc(fdja_l(msg, "tree"));

          flon_rewrite_tree(node, msg);

          expect(fdja_ld(msg, "tree") ===f ""
            "[ ife, {}, 1, [ "
              "[ a, { _0: >, _1: b }, 1, [] ], "
              "[ c, { _0: d }, 1, [] ] "
            "], sx ]");

          expect(fdja_ls(node, "inst", NULL) ===f "ife");
          expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
        }

        it "rewrites  if a > b then c d else f g"
        {
          msg = mrad(
            "if a > b then c d else e f\n"
          );
          //fdja_putdc(fdja_l(msg, "tree"));

          flon_rewrite_tree(node, msg);

          expect(fdja_ld(msg, "tree") ===f ""
            "[ ife, {}, 1, [ "
              "[ a, { _0: >, _1: b }, 1, [] ], "
              "[ c, { _0: d }, 1, [] ], "
              "[ e, { _0: f }, 1, [] ] "
            "], sx ]");

          expect(fdja_ls(node, "inst", NULL) ===f "ife");
          expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
        }

        it "rewrites  elsif a > b then c d"
        {
          msg = mrad(
            "elsif a > b then c d\n"
          );
          //fdja_putdc(fdja_l(msg, "tree"));

          flon_rewrite_tree(node, msg);

          expect(fdja_ld(msg, "tree") ===f ""
            "[ elsif, {}, 1, [ "
              "[ a, { _0: >, _1: b }, 1, [] ], "
              "[ c, { _0: d }, 1, [] ] "
            "], sx ]");

          expect(fdja_ls(node, "inst", NULL) ===f "elsif");
          expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
        }

        it "rewrites  else if a > b then c d"
        {
          msg = mrad(
            "else if a > b then c d\n"
          );
          //fdja_putdc(fdja_l(msg, "tree"));

          flon_rewrite_tree(node, msg);

          expect(fdja_ld(msg, "tree") ===f ""
            "[ elsif, {}, 1, [ "
              "[ a, { _0: >, _1: b }, 1, [] ], "
              "[ c, { _0: d }, 1, [] ] "
            "], sx ]");

          expect(fdja_ls(node, "inst", NULL) ===f "elsif");
          expect(fdja_ld(node, "tree", NULL) ===F fdja_ld(msg, "tree"));
        }
      }
    }

