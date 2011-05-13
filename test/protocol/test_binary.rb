require 'helper'

class TestBinary < Bitcoin::TestCase
  def setup
    @hex_number = 0xCAFEBABE
    @version_message = File.open(File.join(fixture_path, 'version.bin'))
    @version_message2 = File.open(File.join(fixture_path, 'version2.bin'), 'w+')
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
    @version_message.extend(BtcProto::Binary)
    const = BtcProto.lookup([:MAGIC, :production])
    assert_equal const, @version_message.read_uint32_little
  end

  def test_write_uint32_little
    const = BtcProto.lookup([:MAGIC, :production])
    @version_message2.tap do |f|
      f.extend(BtcProto::Binary)
      f.rewind
      f.write_uint32_little(const)
      assert_equal const, f.read_uint32_little
      f.close
    end
  end

  def teardown
    [@version_message, @version_message2].each {|m| m.close}
  end
end

