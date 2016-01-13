
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

    cn = tree[1].collect { |k, v| l_to_tree([ v ], tree[2], node, message) }

    [ op, {}, tree[2], cn, *tree[4] ]
  end

  def rewrite_infix(op, node, message, tree)

    nil
  end

  def rewrite_pinfix(op, node, message, tree)

    rewrite_infix(op, node, message, tree) ||
    rewrite_prefix(op, node, message, tree)
  end

  def rewrite(node, message, tree)

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

    return val if is_tree?(val)

    if val.is_a?(String)
      [ val, {}, lnumber, [] ]
    else
      [ 'val', { '_0' => val }, lnumber, [] ]
    end
  end

  def l_to_tree(lst, lnumber, node, message)

    return v_to_tree(lst.first, lnumber, node, message) if lst.size == 1
  end
end

__END__
  flon source:

static fdja_value *l_to_tree(
  flu_list *l, fdja_value *lnumber, fdja_value *node, fdja_value *msg)
{
  if (l->size == 1) return v_to_tree(l->first->item, lnumber, node, msg);

  fdja_value *r = fdja_array_malloc();

  fdja_push(r, fdja_clone(l->first->item));
  fdja_value *atts = fdja_push(r, fdja_object_malloc());

  size_t index = 0;
  for (flu_node *n = l->first->next; n; n = n->next)
  {
    fdja_value *v = n->item;
    char *key = v->key; if (is_index(key)) key = flu_sprintf("_%zu", index);
    ++index;
    fdja_set(atts, key, fdja_clone(v));
    if (key != v->key) free(key);
  }

  fdja_push(r, fdja_clone(lnumber)); // line number
  fdja_push(r, fdja_array_malloc()); // no children

  return r;
}

