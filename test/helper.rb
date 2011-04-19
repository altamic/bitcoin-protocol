$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

# TODO: resort to test_unit where minitest
# is not available and don't require
# anything
begin; gem 'minitest' if RUBY_VERSION =~ /^1\.9/; rescue Gem::LoadError; end

begin
  require 'minitest/autorun'
rescue LoadError
  require 'rubygems'
  require 'minitest/autorun'
end

require 'bitcoin'
require 'bitcoin/protocol'

module Bitcoin
  class TestCase < MiniTest::Unit::TestCase
    #
    # Test::Unit backwards compatibility
    #
    begin
      alias :assert_no_match   :refute_match
      alias :assert_not_nil    :refute_nil
      alias :assert_raise      :assert_raises
      alias :assert_not_equal  :refute_equal
    end if RUBY_VERSION =~ /^1\.9/

    def fixture_path
      File.join(File.dirname(__FILE__), 'fixtures')
    end

    def lib_path
      File.join(File.dirname(__FILE__), '../lib/bitcoin')
    end

    def random_string(length)
      (0...length).inject("") { |m,n| m  << (?A + rand(25)).chr }
    end

    def random_integer(bits, type=:uint)
      (type.equal? :int) ? -1*rand(2**(bits-1)) : rand(2**bits)
    end

    def pack_integer(integer, opt={:bytes => 4, :type => :uint, :endian => nil})
      bytes, type, endian = opt[:bytes], opt[:type], opt[:endian]
      endian = :big if endian == :network
      endian = :native if endian == nil

      pack_mapping = {
          1 => { :uint => { :native => 'C' },
                 :int  => { :native => 'c' } },
          2 => { :uint => { :native => 'S', :little => 'v', :big => 'n' },
                 :int  => { :native => 's', :little => 'v', :big => 'n' } },
          4 => { :uint => { :native => 'L', :little => 'V', :big => 'N' },
                 :int  => { :native => 'l', :little => 'V', :big => 'N' } },
          8 => { :uint => { :native => 'Q' },
                 :int  => { :native => 'q' } } }

      if bytes == 8 && (endian == :little || endian == :big)
        bytes  = 4
        format = pack_mapping[bytes][type][endian]
        msb, lsb = (integer & 0xFFFFFFFF), (integer >> 16 & 0xFFFFFFFF)
        array = [msb, lsb]
        array.reverse! if [1,"\x01"].include?([1].pack('i')[0]) # little endian
        array.pack(format*2)
      else
        format = pack_mapping[bytes][type][endian]
        [integer].pack(format)
      end

    end
  end
end
