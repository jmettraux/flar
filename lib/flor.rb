
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

require 'json'
require 'thread'

require 'raabro'
require 'munemo'


module Flor

  VERSION = '0.3.0'
end

require 'flor/dollar'
require 'flor/parsers'

require 'flor/instruction'
#
Dir[File.join(File.dirname(__FILE__), 'flor/n/*.rb')].each do |path|
  require path
end

require 'flor/executor'
require 'flor/x/rewrite'


module Flor

  def self.dup(o)

    Marshal.load(Marshal.dump(o))
  end

  def self.tstamp(t=Time.now.utc)

    t.strftime('%Y%m%d.%H%M%S.') + sprintf('%06d', t.usec)
  end

  def self.to_index(s)

    return 0 if s == 'first'
    return -1 if s == 'last'

    i = s.to_i
    fail ::IndexError.new("#{s.inspect} is not an array index") if i.to_s != s

    i
  end

  def self.deep_get(o, k) # --> success(boolean), value

    v = o
    ks = k.split('.')

    loop do

      break unless kk = ks.shift

      case v
        when Array then v = v[to_index(kk)]
        when Hash then v = v[kk]
        else fail ::IndexError.new("#{kk.inspect} not found")
      end
    end

    v
  end

  def self.deep_set(o, k, v) # --> success(boolean)

    o[k] = v

    true
  end

  def self.to_error(o)

    if o.respond_to?(:message)
      { 'msg' => o.message,
        'kla' => o.class.to_s,
        'trc' => o.backtrace[0, 7] }
    else
      { 'msg' => o.to_s }
    end
  end
end

