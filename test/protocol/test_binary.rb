require 'helper'

class TestBinary < Bitcoin::TestCase
  def setup
    @hex_number = 0xCAFEBABE
    @version_message = File.open(File.join(fixture_path, 'version.bin'))
    @version_message2 = File.open(File.join(fixture_path, 'version2.bin'), 'rb+')
    [@version_message, @version_message2].each { |f|
      f.extend(BtcProto::Binary)
    }
    @magic = BtcProto.lookup([:MAGIC, :production])
  end

  def host_endianness
    first_byte = [1].pack('i')[0]
    [1,1.chr].include?(first_byte) ? :little : :big
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

  def test_read_uint32_little
    assert_equal @magic, @version_message.read_uint32_little
  end

  def test_write_uint32_little
    @version_message2.tap do |m|
      m.rewind
      m.write_uint32_little(@magic)
      m.rewind
      assert_equal @magic, m.read_uint32_little
    end
  end

  def test_read_uint64_little
    @version_message2.tap do |m|
      m.pos = 40
      value = m.read_uint64_little
      assert_equal 1, value
    end
  end
  
  def test_write_uint64_little
    @version_message2.tap do |m|
      m.pos = 40
      value = m.write_uint64_little(1)
      m.pos -= 8
      assert_equal 1, m.read_uint64_little
    end
  end

  def test_read_uint16_network
    @version_message2.tap do |m|
      m.rewind
      value = m.read_uint16_network
      assert_equal 63934, value
    end
  end

  def test_write_uint16_network
    @version_message2.tap do |m|
      m.rewind
      m.write_uint16_network(63934)
      m.rewind
      value = m.read_uint16_network
      assert_equal 63934, value
    end
  end


  def teardown
    [@version_message, @version_message2].each {|m| m.close}
  end
end

