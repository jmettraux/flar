
#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


class Flor::Instruction

  def initialize(execution, node, message)

    @execution = execution
    @node = node
    @message = message
  end

  def receive

    [
      { 'point' => 'receive', 'payload' => payload, 'nid' => parent }
    ]
  end

  protected

  def exid; @message['exid']; end
  def nid; @message['nid']; end
  def from; @message['from']; end
  def attributes; tree[1]; end
  def payload; @message['payload']; end
  def parent; @node['parent']; end

  def tree; lookup_tree(nid); end
  def parent_node; @execution['nodes'][parent]; end

  def lookup_tree(nid)

    node = @execution['nodes'][nid]

    tree = node['tree']
    return tree if tree

    tree = lookup_tree(node['parent'])

    id = nid.split('_').last
    id = id.split('-').last
    id = id.to_i

    tree.last[id]
  end

  def touch(node)

    node['mtime'] = Flor.tstamp
  end

  def reply(h={})

    m = {}
    m['point'] = 'receive'
    m['exid'] = exid
    m['nid'] = parent
    m['from'] = nid
    m['payload'] = payload
    m.merge!(h)

    [ m ]
  end

  def error_reply(text)

    # TODO log into execution

    reply('point' => 'failed', 'error' => { 'text' => text })
  end

  def next_id(nid)

    nid.split('_').last.to_i + 1
  end

  def sequence_receive

    i = @message['point'] == 'execute' ? 0 : next_id(from)
    t = tree.last[i]

    if i > 0 && rets = @node['rets']
      rets << Flor.dup(payload['ret'])
    end

    if t == nil
      reply
    else
      reply('point' => 'execute', 'nid' => "#{nid}_#{i}", 'tree' => t)
    end
  end

  def make_schedule_msg(type, time_string, nid, tree0, tree1, msg)

    m = { 'type' => time_string }
    if msg
      m['point'] = 'schedule'
      m['tree0'] = tree0
      m['tree1'] = tree1
      m['msg'] = msg
    else
      m['point'] = 'unschedule'
    end

    m
  end
end

# #expand and co
#
class Flor::Instruction

  def self.split(key)

    m = key.match(/\A([lgd]?)((?:v|var|variable)|w|f|fld|field)\.(.+)\z/)

    m ? [ m[1], m[2][0, 1], m[3] ] : [ nil, 'f', key ]
  end

  class Expander < Flor::Dollar

    def initialize(inst)

      @execution, @node, @message =
        inst.instance_eval { [ @execution, @node, @message ] }
    end

    def lookup(k)

      do_lookup(@node, k)
    end

    protected

    def do_lookup(node, k)

      mod, cat, k = Flor::Instruction.split(k)

      if cat == 'v'
        node['vars'][k]
      elsif cat == 'w'
        nil
      else # field
        @message['payload'][k]
      end
    end
  end

  def expand(s)

    s.index('$') ? Expander.new(self).expand(s) : s
  end
end

# class methods
#
class Flor::Instruction

  @@instructions = {}

  def self.names(*names)

    names.each { |n| @@instructions[n] = self }
  end
  class << self; alias :name :names; end

  def self.lookup(name)

    @@instructions[name]
  end
end

# A namespace for instruction implementations
#
module Flor::Ins; end

