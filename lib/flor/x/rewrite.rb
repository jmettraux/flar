
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
    (o[0].is_a?(String) || is_tree?(o[0])) &&
    o[3].all? { |e| is_tree?(e) } # overkill?
  end

#static int rewrite_as_call_invoke_or_val(
#  fdja_value *node, fdja_value *msg, fdja_value *tree)
#{
#  int r = 0; // "not rewritten" for now
#
#  fdja_value *vname = fdja_l(tree, "0");
#  char *name = NULL;
#
#  if ( ! fdja_is_stringy(vname)) goto _over;
#
#  name = fdja_to_string(vname);
#
#  if (lookup_instruction('e', name)) goto _over;
#
#  r = 1; // "rewritten" for now
#
#  fdja_value *v = lookup_var(node, 'l', name); // 'l' for "local"
#
#  if (is_callable(v))
#  {
#    //fdja_psetv(node, "inst", "call");
#    fdja_replace(fdja_l(tree, "0"), fdja_s("call"));
#    unshift_attribute(name, tree);
#  }
#  else if (fdja_lz(tree, "1") == 0 && fdja_lz(tree, "3") == 0)
#  {
#    fdja_replace(fdja_l(tree, "0"), fdja_s("val"));
#    unshift_attribute(name, tree);
#  }
#  else
#  {
#    r = 0;
#  }
#
#  return r;
#}
  def rewrite_as_call_invoke_or_val(node, message, tree)

    tree
  end

  def rewrite_prefix(op, node, message, tree)

    return tree unless tree[0] == op
    return tree if tree[3].length > 0 # there are already children

    cn = tree[1]
      .collect { |k, v| l_to_tree([ [ nil, v ] ], tree[2], node, message) }

    [ op, {}, tree[2], cn, *tree[4] ]
  end

  def rewrite_infix(op, node, message, tree)

    return tree unless tree[1].find { |k, v| v == op && k.match(/\A_\d+\z/) }

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

    [ op, {}, tree[2], cn, *tree[4] ]
  end

  def rewrite_pinfix(op, node, message, tree)

    t = rewrite_infix(op, node, message, tree)
    t = rewrite_prefix(op, node, message, t)

    t
  end

  def rewrite_else_if(node, message, tree)

    return tree unless tree[0] == 'else'
    return tree unless tree[1]['_0'] == 'if'

    as =
      tree[1].inject([ {}, -1 ]) do |(h, i), (k, v)|
        k =
          if k == '_0'
            nil
          elsif k.match(/\A_\d+\z/)
            i = i + 1
            "_#{i}"
          else
            k
          end
        h[k] = v if k

        [ h, i ]
      end.first

    [ 'elsif', as, tree[2], tree[3], *tree[4] ]
  end

  def rewrite_post_if(node, message, tree)

    foe = nil
    preif = []
    postif = nil
    #
    tree[1].each do |k, v|
      if postif
        postif << [ k, v ]
      elsif v == 'if' || v == 'unless'
        postif = []
        foe = v
      else
        preif << [ k, v ]
      end
    end

    return tree unless foe

    postt = l_to_tree(postif, tree[2], node, message)

    pret = l_to_tree([ [ nil, tree[0] ]  ] + preif, tree[2], node, message)
    pret[3] = tree[3]

    [ foe == 'if' ? 'ife' : 'unlesse', {}, tree[2], [ postt, pret ], *tree[4] ]
  end

  def rewrite_head_if(node, message, tree)

    return tree unless %w[ if elif elsif unless else ].include?(tree[0])

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

    inst =
      if thn.any?
        if tree[0][0, 1] == 'u'
          'unlesse'
        elsif tree[0][0, 1] == 'e'
          'elsif'
        else
          'ife'
        end
      else
        tree[0]
      end

    [ inst, {}, tree[2], cn, *tree[4] ]
  end

  def rewrite_set(node, message, tree)

    return tree if tree[0] != 'set'
    return tree if tree[3].any? # one or more children

    return tree if tree[1].empty? # no attributes
    return tree if tree[1].keys == [ '_0' ] # only _0 attribute

    ln = tree[2]

    sets =
      tree[1].inject([]) do |a, (k, v)|
        next a if k.match(/\A_\d+\z/)
        a << [ 'set', { '_0' => k }, ln, [ v_to_tree([ k, v ], ln, node, message) ] ]
        a
      end

    r = sets.size == 1 ? sets.first : [ 'sequence', {}, ln, sets ]
    r << tree[4] if tree[4]

    r
  end

  def rewrite_parens(node, message, tree)

    return tree unless tree[1].values.find { |c| is_tree?(c) }

    ln = tree[2]
    catts = {}
    core = [ tree[0], catts, ln, tree[3] ]
    schildren = []

    j = 0
    tree[1].each do |k, v|
      if is_tree?(v)
        schildren << [ 'set', { '_0' => "w._#{j}" }, ln, [ v ] ]
        catts[k] = "$(w._#{j})"
        j = j + 1
      else
        catts[k] = v
      end
    end

    schildren << core

    [ 'sequence', {}, ln, schildren, *tree[4] ]
  end

  def rewrite(node, message, tree)

    t = rewrite_as_call_invoke_or_val(node, message, tree);

    t = rewrite_else_if(node, message, t)
    t = rewrite_post_if(node, message, t)
    t = rewrite_head_if(node, message, t)

    t = rewrite_set(node, message, t)

    # in precedence order
    #
    t = rewrite_pinfix('or', node, message, t)
    t = rewrite_pinfix('and', node, message, t)
    #
    t = rewrite_pinfix('==', node, message, t)
    t = rewrite_pinfix('!=', node, message, t)
    #
    t = rewrite_pinfix('=~', node, message, t)
    t = rewrite_pinfix('!~', node, message, t)
    #
    t = rewrite_pinfix('>', node, message, t)
    t = rewrite_pinfix('>=', node, message, t)
    t = rewrite_pinfix('<', node, message, t)
    t = rewrite_pinfix('<=', node, message, t)
    #
    t = rewrite_pinfix('+', node, message, t)
    t = rewrite_pinfix('-', node, message, t)
    t = rewrite_pinfix('*', node, message, t)
    t = rewrite_pinfix('/', node, message, t)
    t = rewrite_pinfix('%', node, message, t)

    t = rewrite_parens(node, message, t);

    t
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

