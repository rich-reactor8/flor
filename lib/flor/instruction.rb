
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


class Flor::Node

  def initialize(execution, node, message)

    @execution = execution
    @node = node
    @message = message
  end

  def lookup_tree(nid)

    node = @execution['nodes'][nid]
    return nil unless node

    tree = node['tree']
    return tree if tree

    tree = lookup_tree(node['parent'])
    #return nil unless tree # let it fail...

    id = nid.split('_').last
    id = id.split('-').last
    id = id.to_i

    tree.last[id]
  end

  def lookup(name)

    cat, mod, key = key_split(name)

    cat == 'v' ? lookup_var(@node, mod, key) : lookup_field(mod, key)
  end

  protected

  def exid; @message['exid']; end
  def nid; @message['nid']; end
  def from; @message['from']; end
  def attributes; tree[1]; end
  def payload; @message['payload']; end
  def parent; @node['parent']; end

  def tree

    lookup_tree(nid)
  end

  def parent_node(node)

    @execution['nodes'][node['parent']]
  end

  def lookup_dvar(mod, key)

    return nil if mod == 'd' # FIXME

    Flor::Executor.instructions[key]
  end

  def lookup_var(node, mod, key)

    return lookup_dvar(mod, key) if node == nil || mod == 'd'

    pnode = parent_node(node)

    if mod == 'g'
      return node['vars'][key] if pnode == nil
      return lookup_var(pnode, mod, key)
    end

    vars = node['vars']

    return vars[key] if vars && vars.has_key?(key)

    lookup_var(pnode, mod, key)
  end

  def key_split(key) # => category, mode, key

    m = key.match(/\A(?:([lgd]?)((?:v|var|variable)|w|f|fld|field)\.)?(.+)\z/)

    #fail ArgumentError.new("couldn't split key #{key.inspect}") unless m
      # spare that

    ca = (m[2] || 'v')[0, 1]
    mo = m[1]; mo = 'l' if ca == 'v' && (mo == nil || mo == '')
    ke = m[3]

    #p [ key, '-->', ca, mo, ke ]
    [ ca, mo, ke ]
  end
end

class Flor::Instruction < Flor::Node

  def self.names(*names)

    names.each { |n| Flor::Executor.instructions[n] = self }
  end

  class << self; alias :name :names; end

  protected

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

  def error_reply(o)

    reply('point' => 'failed', 'error' => Flor.to_error(o))
  end

  def lookup_var_node(mode, node)

    vars = node['vars']
    return node if mode == 'l' && vars

    par = parent_node(node)
    return node if vars && par == nil && mode == 'g'
    return lookup_var_node(mode, par) if par

    nil
  end

  def set_var(mode, k, v)

    fail IndexError.new("cannot set domain variables") if mode == 'd'

    if node = lookup_var_node(mode, @node)

      b, v = Flor.deep_set(node['vars'], k, v)

      return v if b
    end

    fail IndexError.new("couldn't set var #{mode}v.#{k}")
  end

  def set_field(k, v)

    success, value = Flor.deep_set(payload, k, v)

    fail IndexError.new("couldn't set field #{k}") unless success

    value
  end

  def set_value(k, v)

    #return if k == '_'

    cat, mod, key = key_split(k)

    case cat[0]
      when 'f' then set_field(key, v)
      when 'v' then set_var(mod, key, v)
      #when 'w' then set_war(key, v)
      else fail IndexError.new("don't know how to set #{k.inspect}")
    end
  end
end

# A namespace for instruction implementations
#
module Flor::Ins; end
