
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
    end
  end
end

