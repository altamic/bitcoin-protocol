require 'helper'

class TestTypes < Bitcoin::TestCase
  # a type should know its size
  # a type should be able to serialize itself
  # a type should be able do deserialize itself
  # a type can be a collection of types
  # a type can a collection of different types
  # mappings should contain classes
  def test_write_encoded_size
    skip
    content = 'The ‘illusory’ money-energy that is spent by the borrower is accumulated via the depreciated value of the lender’s fractional money'
    assert content.size < 252
    buf = BtcProto::Buffer.of_size(1 + content.size) do
      write_encoded_string(content)
    end
    assert_equal content.size, buf.read_encoded_size
  end

  def test_read_encoded_string_case_one
    skip
    content = 'There is some remote possibility and flickering indication that new emerging digital currencies could scale “parasite free.”'
    buf = BtcProto::Buffer.of_size(1 + content.size) do
      write_uint8(content.size)
      write_fixed_size_string(content)
    end
    assert((1..252).include?(buf.size))
    assert_equal content, buf.read_encoded_string
  end

  def test_read_encoded_string_case_two
    skip
    n = rand(0xFFFF - 253 + 1) + 253
    rand_str = random_string(n)
    buf = BtcProto::Buffer.of_size(1+2+n) do
      write_uint8(253)
      write_uint16(n)
      write_string(rand_str, :size => n)
    end
    assert((253..0xFFFF).include?(buf.size))
    str = buf.read_encoded_string
    assert_equal rand_str, str
  end

  def test_read_encoded_string_case_three
    skip
    n = 0x10000 + 1
    rand_str = random_string(n)
    buf = BtcProto::Buffer.of_size(1+4+n) do
      write_uint8(254)
      write_uint32(n)
      write_string(rand_str, :size => n)
    end
    assert((0x10000..0xFFFFFFFF).include?(buf.size))
    str = buf.read_encoded_string
    assert_equal rand_str, str
  end

  def test_write_encoded_string_case_one
    skip
    n = rand(252)
    rand_str = random_string(n)
    buf = BtcProto::Buffer.of_size(1+n) {
      write_encoded_string(rand_str)
    }
    assert_equal rand_str.size, buf.content[0]
    assert_equal rand_str, buf.read_encoded_string
  end

  def test_write_encoded_string_case_two
    skip
    n = rand(0xFFFF - 253 + 1) + 253
    rand_str = random_string(n)
    buf = BtcProto::Buffer.of_size(1+2+n) do
      write_encoded_string(rand_str)
    end
    assert_equal rand_str, buf.read_encoded_string
  end

  # def test_write_encoded_bignum_vector
    # bn_v = []
    # 5.times { bn_v << rand(2**256) }
    # buf = BtcProto::Buffer.of_size(256 + 3) do
      # write_encoded_size(bn_v.size)
      # bn_v.size.times {|i| write_uint256_little(bn_v[i])}
    # end
  # end

  # def test_size_encoded_bignum_vector_size
    # bn_v = [1,2,3,4,5]
    # buf = BtcProto::Buffer.of_size(312) do
      # write_encoded_size(bn_v.size)
      # bn_v.size.times {|i| write_uint256_little(bn_v[i])}
    # end
    # assert_equal 5, buf.read_encoded_size
  # end

  # def test_read_encoded_bignum_vector
    # bn_v = [1,2,3,4,5]
    # buf = BtcProto::Buffer.of_size(312) do
      # write_encoded_size(bn_v.size)
      # bn_v.size.times {|i| write_uint256_little(bn_v[i])}
    # end
    # assert_equal bn_v, buf.read_encoded_bignum_vector
  # end

  def test_read_address
    size = 1 + 8 + 16 + 2
    buf = BtcProto::Buffer.of_size(size) do
      write_encoded_size(size)
      write_uint64_little(1)             # services
      write_uint128_network(0xFFFF00000000)  # ip_address
      write_uint16_network(8333)             # port
    end
    obj = BtcProto::Address.load(buf)
    assert_instance_of BtcProto::Address, obj

    assert_equal 1,              obj.services
    assert_equal 0xFFFF00000000, obj.ip_address
    assert_equal 8333,           obj.port
  end

  # def test_read_outpoint
    # hash = rand(2**256)
    # size = 1 + 32 + 4

    # buf = BtcProto::Buffer.of_size(size) do
      # write_encoded_size(size)
      # write_uint256_little(hash)  # hash
      # write_uint32_little(size)   # size
    # end

    # obj = BtcProto::OutPoint.load(buf)
    # assert_instance_of BtcProto::OutPoint, obj
    
    # assert_equal hash, obj.hash
    # assert_equal 37,   obj.size
  # end

  def test_read_tx_input
    # previous = BtcProto::OutPoint.new
    # _buf     = BtcProto::Buffer.of_size(7)
    # encoded_string = _buf.write_encoded_string('OP_NIL').dump
    # _buf2    = BtcProto::Buffer.of_size(4)
    # seq_num  = rand(2**32)
    # sequence = _buf2.write_uint32_little(seq_num).dump

    # out_point      :previous
    # encoded_string :script_signature
    # uint32_little  :sequence

    # previous
    # script_signature
    # sequence
  end

  def test_read_tx_output

  end

  def test_read_inventory
    
  end

  def test_block_locator
    
  end

  def test_transaction
    
  end
end

BtcProto::Types.mappings.each_pair do |name, klass|
  test_name = "test_#{name}_is_mapped_to_a_class"
  TestTypes.class_eval do
    define_method(test_name) do
      assert name.is_a? Symbol
      assert_equal Class, klass.class
    end
  end
end

