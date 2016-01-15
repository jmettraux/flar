
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


class Flor::Executor

  protected

  def is_tree?(o)

    o.is_a?(Array) &&
    o[1].is_a?(Hash) &&
    o[2].is_a?(Fixnum) &&
    o[3].is_a?(Array) &&
    o[3].all? { |e| is_tree?(e) } # overkill?
  end

  def rewrite_prefix(op, node, message, tree)

    return nil unless tree[0] == op
    return nil if tree[3].length > 0 # there are already children

    cn = tree[1]
      .collect { |k, v| l_to_tree([ [ nil, v ] ], tree[2], node, message) }

    [ op, {}, tree[2], cn, *tree[4] ]
  end

  def rewrite_infix(op, node, message, tree)

    return nil unless tree[1].find { |k, v| v == op && k.match(/\A_\d+\z/) }

    cn = []
    l = [ [ nil, tree[0] ] ]

    (tree[1].keys + [ nil ]).each do |k|

      v = tree[1][k]

      if k && ! (v == op &&  k.match(/\A_\d+\z/))
        l << [ k, v ]; next
      end

      cn << l_to_tree(l, tree[2], node, message)
      l = []
    end

    [ op, {}, tree[2], cn ]
  end

  def rewrite_pinfix(op, node, message, tree)

    rewrite_infix(op, node, message, tree) ||
    rewrite_prefix(op, node, message, tree)
  end

  def rewrite_else_if(node, message, tree)

    nil # TODO
  end

  def rewrite_post_if(node, message, tree)

    nil # TODO
  end

  def rewrite_head_if(node, message, tree)

    return nil unless %w[ if elif elsif unless else ].include?(tree[0])

    cn = Flor.dup(tree[3])

    cnd = []; thn = []; els = []
    l = cnd

    tree[1].each do |k, v|
      case v
        when 'then' then l = thn
        when 'else' then l = els
        else l << [ k, v ]
      end
    end

    if cnd.any?
      if thn.any?
        if els.any?
          cn.unshift(l_to_tree(els, tree[2], node, message))
        end
        cn.unshift(l_to_tree(thn, tree[2], node, message))
      end
      cn.unshift(l_to_tree(cnd, tree[2], node, message))
    end

    #if (has_then)
    #{
    #  char *inst = "ife";
    #  if (*fdja_srk(tree->child) == 'u') inst = "unlesse";
    #  else if (*fdja_srk(tree->child) == 'e') inst = "elsif";
    #  fdja_replace(tree->child, fdja_v(inst));
    #}
    if thn.any?
    end

    [ tree[0], {}, tree[2], cn ]
  end

  def rewrite(node, message, tree)

    rewrite_else_if(node, message, tree) ||
    rewrite_post_if(node, message, tree) ||
    rewrite_head_if(node, message, tree) ||

    # in precedence order
    #
    rewrite_pinfix('or', node, message, tree) ||
    rewrite_pinfix('and', node, message, tree) ||
    #
    rewrite_pinfix('==', node, message, tree) ||
    rewrite_pinfix('!=', node, message, tree) ||
    #
    rewrite_pinfix('=~', node, message, tree) ||
    rewrite_pinfix('!~', node, message, tree) ||
    #
    rewrite_pinfix('>', node, message, tree) ||
    rewrite_pinfix('>=', node, message, tree) ||
    rewrite_pinfix('<', node, message, tree) ||
    rewrite_pinfix('<=', node, message, tree) ||
    #
    rewrite_pinfix('+', node, message, tree) ||
    rewrite_pinfix('-', node, message, tree) ||
    rewrite_pinfix('*', node, message, tree) ||
    rewrite_pinfix('/', node, message, tree) ||
    rewrite_pinfix('%', node, message, tree) ||
    #
    tree
  end

  def v_to_tree(val, lnumber, node, message)

    val = val[1]

    return val if is_tree?(val)
    return [ val, {}, lnumber, [] ] if val.is_a?(String)
    [ 'val', { '_0' => val }, lnumber, [] ]
  end

  def l_to_tree(lst, lnumber, node, message)

    return v_to_tree(lst.first, lnumber, node, message) if lst.size == 1

    as, _ =
      lst[1..-1].inject([ {}, 0 ]) do |(h, i), (k, v)|
        if k.match(/\A_\d+\z/) then k = "_#{i}"; i = i + 1; end
        h[k] = v
        [ h, i ]
      end

    [ lst.first[1], as, lnumber, [] ]
  end
end

