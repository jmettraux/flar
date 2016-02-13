
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


class Flor::Ins::Call < Flor::Instruction

  name 'call'

  def execute

    fna = attributes['_0']
    fun = get_value(fna)

    return error_reply("no function named #{fna.inspect}") unless fun


    named = fun['signature'][0] == 'define'

    sargs = fun['signature'][1].reject { |k, v| named && k == '_0' }
    cargs = attributes.reject { |k, v| k == '_0' }.to_a

    vars = {}

    cargs.each do |cak, cav|

      if cak.match(/\A_\d+\z/)
        sa = sargs[cak]
        _, sam, sak = key_split(sa)
        (sam == 'v' ? vars : payload)[sak] = cav
      else
        puts "-" * 70
        p cak
        puts ("-" * 70) + '.'
      end
    end

    reply(
      'point' => 'execute',
      'nid' => "#{nid}_0",
      'tree' => fun['tree'],
      'vars' => vars)
  end
end

