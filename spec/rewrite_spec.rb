
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

    node = {
      'nid' => '0',
      'parent' => nil,
      'ctime' => now,
      'mtime' => now }

    executor.execution['nodes']['0'] = node

    message = {
      'point' => 'execute',
      'tree' => tree = tree.is_a?(String) ? Flor::Radial.parse(tree) : tree,
      'vars' => opts[:vars] || opts['vars'],
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
  end
end

