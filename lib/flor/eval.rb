
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


module Flor

  def self.eval(tree, fields, variables)

    tree = tree.is_a?(String) ? Flor::Radial.parse(tree) : tree
    exid = generate_exid('eval')

    execution = {
      'exid' => exid,
      'nodes' => {},
      'errors' => [] }

    messages = []

    messages <<
      { 'point' => 'execute',
        'exid' => exid,
        'nid' => '0',
        'tree' => tree,
        'payload' => fields,
        'vars' => variables }

    message = nil

    loop do

      message = messages.pop

      break unless message

      log(message)

      point = message['point']

      break if point == 'failed'
      break if point == 'terminated'

      #tree = determine_tree(execution, message)
      #msgs = inst.send(point.to_sym)
      msgs = self.send(point.to_sym, execution, message)

      messages.concat(msgs)
    end

    message
  end

  def self.execute(execution, message)

    nid = message['nid']
    tree = message['tree']

    # TODO rewrite tree

    kinst = Flor::Instruction.lookup(tree.first)
    inst = kinst.new(execution, message)

    now = Flor.tstamp

    execution['nodes'][nid] = {
      'nid' => nid,
      'tree' => tree,
      'parent' => message['from'],
      'ctime' => now,
      'mtime' => now }

    inst.execute
  end

  def self.receive(execution, message)

    nid = message['nid']

    return [
      message.merge('point' => 'terminated')
    ] if nid == nil

    tree = execution['nodes'][nid]['tree']

    kinst = Flor::Instruction.lookup(tree.first)
    inst = kinst.new(execution, message)

    inst.receive
  end

  def self.generate_exid(domain)

    @exid_counter ||= 0
    @exid_mutex ||= Mutex.new

    local = true

    uid = 'u0'

    t = Time.now
    t = t.utc unless local

    sus =
      @exid_mutex.synchronize do

        sus = t.sec * 100000000 + t.usec * 100 + @exid_counter

        @exid_counter = @exid_counter + 1
        @exid_counter = 0 if @exid_counter > 99

        Munemo.to_s(sus)
      end

    t = t.strftime('%Y%m%d.%H%M')

    "#{domain}-#{uid}-#{t}.#{sus}"
  end

  def self.log(m)

    return

    pt = m['point'][0, 3]
    ni = m['nid'] ? " #{m['nid']}" : ''
    fr = m['from'] ? " from #{m['from']}" : ''
    t = m['tree'] ? ' ' + m['tree'][0..-2].inspect : ''

    puts "#{pt}#{ni}#{t}#{fr}"
  end
end

