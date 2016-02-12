
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


class Flor::Ins::Set < Flor::Instruction

  name 'set'

  def execute

    @node['rets'] = []

    sequence_receive
  end

  def receive

    ms = sequence_receive
    return ms if ms.first['point'] == 'execute'

    val = payload['ret']
    uks = unkeyed_values(true)

    if val.is_a?(Array) && uks.size > 1
      splat(uks, val)
    else
      set_value(uks.first, val)
    end

    reply
  end

  protected

  def splat(ks, vs)

    ks.inject(0) { |off, k|
      if k[0, 1] == '*'
        #p({ off: off, k: k, ks: ks[off + 1..-1], vs: vs[off..-1] })
        l = vs.length - ks.length + 1
        set_value(k[1..-1], vs[off, l])
        off + l
      else
        set_value(k, vs[off])
        off + 1
      end
    }
  end
end

