
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

  def initialize(execution, message)

    @execution = execution
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
  def node; @execution['nodes'][nid]; end
  def tree; node['tree']; end
  def attributes; tree[1]; end
  def payload; @message['payload']; end
  def parent; node['parent']; end

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

module Flor::Ins; end

