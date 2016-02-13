
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

  class Executor

    attr_reader :execution
    attr_reader :options

    def initialize(opts)

      @options = opts
    end

    protected

    def make_launch_msg(tree, opts)

      t = tree.is_a?(String) ? Flor::Radial.parse(tree, opts[:fname], opts) : t

      unless t
        #h = opts.merge(prune: false, rewrite: false)
        #p Flor::Radial.parse(tree, h[:fname], h)
          # TODO re-parse and indicate what went wrong...
        fail ArgumentError.new('radial parse failure')
      end

      { 'point' => 'execute',
        'exid' => @execution['exid'],
        'nid' => '0',
        'tree' => t,
        'payload' => opts[:payload] || opts[:fields] || {},
        'vars' => opts[:variables] || {} }
    end

    def execute(message)

      nid = message['nid']

      now = Flor.tstamp

      node = {
        'nid' => nid,
        'parent' => message['from'],
        'ctime' => now,
        'mtime' => now }

      if vs = message['vars']
        node['vars'] = vs
      end
      if vs = message['tree'][1]['vars']
        node['vars'] = (node['vars'] || {}).merge(vs) if vs.is_a?(Hash)
      end

      @execution['nodes'][nid] = node

      rewrite_tree(node, message)

      kinst = Flor::Instruction.lookup(node['inst'])

      return error_reply(
        node, message, "no instruction named '#{node['inst']}'"
      ) if kinst == nil

      inst = kinst.new(@execution, node, message)

      inst.execute
    end

    def expand(o, expander)

      case o
        when Array
          o.collect { |e| expand(e, expander) }
        when Hash
          o.inject({}) { |h, (k, v)|
            h[expand(k, expander)] = expand(v, expander); h }
        when String
          expander.expand(o)
        else
          o
      end
    end

    def rewrite_tree(node, message)

      tree0 = message['tree']

      expander = Flor::Instruction.new(@execution, node, message)

      tree1 = [ *expand(tree0[0, 2], expander), *tree0[2..-1] ]
      tree1 = rewrite(node, message, tree1)

      # TODO beware always reduplicating the tree children
      # TODO should be OK, the rewrite_ methods return a new tree as soon
      #      as they rewrite

      node['inst'] = tree1.first
      node['tree'] = tree1 if node['nid'] == '0' || tree1 != tree0
    end

    def receive(message)

      nid = message['nid']
      from = message['from']

      fnode = @execution['nodes'].delete(from) || {}
        # TODO eventually: don't remove if it's a closure

      return [
        message.merge('point' => 'terminated', 'vars' => fnode['vars'])
      ] if nid == nil

      node = @execution['nodes'][nid]

      kinst = Flor::Instruction.lookup(node['inst'])
      inst = kinst.new(@execution, node, message)

      inst.receive
    end

    def log(m)

      return unless @options[:debug]

      pt = m['point'][0, 3]
      ni = m['nid'] ? " #{m['nid']}" : ''
      fr = m['from'] ? " from #{m['from']}" : ''
      t = m['tree'] ? ' ' + m['tree'][0..-2].inspect : ''

      puts "#{pt}#{ni}#{t}#{fr}"
    end

    def generate_exid(domain)

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

    def error_reply(node, message, o)

      # TODO: use node (which may be nil)

      m = { 'point' => 'failed' }
      m['exid'] = message['exid']
      m['nid'] = message['nid']
      m['from'] = message['from']
      m['payload'] = message['payload']
      m['tree'] = message['tree']
      m['error'] = Flor.to_error(o)

      [ m ]
    end
  end

  class TransientExecutor < Executor

    def initialize(opts={})

      super(opts)

      @execution = {
        'exid' => generate_exid('eval'),
        'nodes' => {},
        'errors' => [] }
    end

    def launch(tree, opts={})

      messages = [ make_launch_msg(tree, opts) ]
      message = nil

      loop do

        message = messages.pop

        break unless message

        log(message)

        point = message['point']

        break if point == 'failed'
        break if point == 'terminated'

        msgs =
          begin
            self.send(point.to_sym, message)
          rescue => e
            error_reply(nil, message, e)
          end

        messages.concat(msgs)
      end

      message
    end
  end
end

