require 'helper'

class TestBinary < Bitcoin::TestCase
  def host_endianness
    first_byte = [1].pack('i')[0]
    [1,"\x01"].include?(first_byte) ? :little : :big
  end

  def test_detect_platform_endianness
    assert_equal BtcProto::Binary::NATIVE_BYTE_ORDER, host_endianness
  end

  def test_detect_platform_integer_size
    assert_equal BtcProto::Binary::INTEGER_SIZE_IN_BYTES, 1.size
  end

  def test_buffer_includes_binary
    assert(BtcProto::Buffer.included_modules & [Bitcoin::Protocol::Binary])
  end

  def test_read_correctly_1_byte
    buf = BtcProto::Buffer.of_size(2) {
      write_uint8(0x55)
    }
    assert_equal 0x55, buf.read_uint8
  end

  def test_does_not_care_about_overflow
    overflow = 0xFF + 1
    buf = BtcProto::Buffer.of_size(1) {
      write_uint8(overflow)
    }
    assert_equal 0, buf.read_uint8
  end

  def test_read_correctly_2_bytes
    buf = BtcProto::Buffer.of_size(2) {
      write_uint16_little(0x55)
    }
    assert_equal 0x55, buf.read_uint16_little
  end

  def test_does_not_care_about_overflow_for_uint32
    overflow = 0xFFFFFFFF + 1
    buf = BtcProto::Buffer.of_size(4) {
      write_uint32(overflow)
    }
    assert_equal 0, buf.read_uint32
  end

  def test_read_correctly_4_bytes
    v2 = "\324{\000\000"
    v2.reverse! if host_endianness.equal? :little
    buf = BtcProto::Buffer.new(v2)
    value = 0
    buf.size.times do |i|
      assert_equal v2[i], buf.read_uint8
    end
  end

  def test_write_fixed_size_string
    content = 'new blips are arbitrarily created in the electronic transaction system of the Federal Reserve (known as FedWire), no outside detection is possible whatsoever because there is no outside system that verifies (or even can verify) the total quantity of FedWire deposits'
    buf = BtcProto::Buffer.of_size(content.size) {
      write_fixed_size_string(content)
    }
    assert_equal content, buf.content
  end

  def test_find_bytesize_for_int16_little
    assert_equal 2, BtcProto::Buffer.new('').size_of('read_int16_little')
  end

  def test_write_uint64
    bytes = [0xB7, 0x0A, 0x46, 0x25, 0xF1, 0xA2, 0x24, 0xCF]
    bytes.reverse! if BtcProto::Binary::NATIVE_BYTE_ORDER.equal? :little
    buf = BtcProto::Buffer.of_size(8) { write_uint64_big(n) }
    bytes.each_with_index do |byte, i|
      buf.position = i
      assert_equal byte, buf.read_uint8
    end
    buf.rewind
    expected = bytes.pack("C"*bytes.size)
    assert_equal n, buf.read_uint64
  end

  def test_read_uint128_little
    n = rand(2**128)
    assert_equal 16, n.size
    buf = BtcProto::Buffer.of_size(16) { write_uint128_little(n) }
    assert_equal n, buf.read_uint128_little
  end

  def test_read_uint256_little
    n = rand(2**256)
    assert_equal 32, n.size
    buf = BtcProto::Buffer.of_size(32) { write_uint256_little(n) }
    assert_equal n, buf.read_uint256_little
  end

  def test_read_int128_little
    skip
    n = -rand(2**127)
    assert_equal 16, n.size
    buf = BtcProto::Buffer.of_size(16) { write_int128_little(n) }
    assert_equal n, buf.read_int128_little
  end

  def test_read_int256_little
    skip
    n = -rand(2**255)
    assert_equal 32, n.size
    buf = BtcProto::Buffer.of_size(32) { write_int256_little(n) }
    assert_equal n, buf.read_int256_little
  end
end

# test read
bytes_ary = BtcProto::Binary.
              send(:class_variable_get, :@@pack_mappings).keys.sort

bytes_ary.each do |bytes|
  [:int, :uint].each do |type|
    [:native, :little, :big, :network].each do |mapped_endian|
      next if bytes.equal? 1
      TestBinary.class_eval do
        bits    = bytes * 8
        packing = { :bytes => bytes, :type => type, :endian => mapped_endian }

        # read
        read_method = "read_#{type}#{bits}_#{mapped_endian}"
        define_method "test_#{read_method}" do
          number = random_integer(bits, type)
          packed_number = pack_integer(number, packing)
          buf = BtcProto::Buffer.new(packed_number)
          assert number, buf.send(read_method)
        end

        # write
        write_method = "write_#{type}#{bits}_#{mapped_endian}"
        define_method "test_#{write_method}" do
          number = random_integer(bits, type)
          buf = BtcProto::Buffer.of_size(bytes) { send(write_method, number) }
          assert number, buf.send(read_method)
        end

        #size
        define_method "test_#{type}#{bits}_length_is_#{bytes}_bytes" do
          assert bytes, BtcProto::Buffer.new('').size_of(read_method)
          assert bytes, BtcProto::Buffer.new('').size_of(write_method)
        end
      end
    end
    [nil].each do |no_endian_specified|
      bits = bytes * 8
      packing = { :bytes => bytes,
                  :type => type,
                  :endian => no_endian_specified }

      TestBinary.class_eval do
        read_method = "read_#{type}#{bits}"
        define_method "test_#{read_method}" do
          number = random_integer(bits, type)
          packed = pack_integer(number, packing)
          buf = BtcProto::Buffer.new(packed)
          assert number, buf.send(read_method)
        end

        write_method = "write_#{type}#{bits}"
        define_method "test_#{write_method}" do
          number = random_integer(bits, type)
          buf = BtcProto::Buffer.of_size(bytes) {
            send(write_method, number)
          }
          assert number, buf.send(read_method)
        end
      end
    end
  end
end

