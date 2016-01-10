
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

require 'raabro'


module Flor

  class Dollar

    module Parser include Raabro

#static fabr_tree *_str(fabr_input *i)
#{
#  return fabr_rex("s", i,
#    "("
#      "\\\\\\)" "|"
#      "[^\\$\\)]" "|"
#      "\\$[^\\(]"
#    ")+");
#}
      def istr(i)
        rex(:str, i, %r{
          ( \\\) | [^\$)] | \$[^(] )+
        }x)
      end

#static fabr_tree *_outerstr(fabr_input *i)
#{
#  return fabr_rex("s", i,
#    "("
#      "[^\\$]" "|" // doesn't mind ")"
#      "\\$[^\\(]"
#    ")+");
#}
      def ostr(i)
        rex(:str, i, %r{
          ( [^\$] | \$[^(] )+
        }x)
      end

      def pe(i); str(nil, i, ')'); end
      def dois(i); alt(nil, i, :dollar, :istr); end
      def span(i); rep(:span, i, :dois, 0); end
      def dps(i); str(nil, i, '$('); end
      def dollar(i); seq(:dollar, i, :dps, :span, :pe); end
      def doos(i); alt(nil, i, :dollar, :ostr); end
      def outer(i); rep(:span, i, :doos, 0); end

      def rewrite_str(t)
        t.string
      end
      def rewrite_dollar(t)
        cn = rewrite(t.children[1])
        c = cn.first
        if cn.size == 1 && c.is_a?(String)
          [ :dol, c ]
        else
          [ :dol, cn ]
        end
      end
      def rewrite_span(t)
        t.children.collect { |c| rewrite(c) }
      end
    end

#// pipe parser
#
#static fabr_tree *_nopi(fabr_input *i) { return fabr_rex("s", i, "[^|]+"); }
#static fabr_tree *_pi(fabr_input *i) { return fabr_rex("p", i, "\\|\\|?"); }
#
#static fabr_tree *_pipe_parser(fabr_input *i)
#{
#  return fabr_jseq(NULL, i, _nopi, _pi);
#}

    #def lookup(s)
    #  # ...
    #end

    def do_eval(t)

      return t if t.is_a?(String)
      return t.collect { |c| do_eval(c) }.join if t[0] != :dol
      lookup(do_eval(t[1]))
    end

    def expand(s)

      return s unless s.index('$')

      #Parser.parse(s, rewrite: false, all: true, prune: false)
      #Parser.parse(s, rewrite: false)
      t = Parser.parse(s)
      do_eval(t)
    end
  end
end

