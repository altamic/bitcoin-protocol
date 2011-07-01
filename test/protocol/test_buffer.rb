require 'helper'

class TestBuffer < Bitcoin::TestCase
  # Spec
  # A buffer is an IO entity able to
  # - hold content
  # - perform seeks
  # - manage the seek position
  # - read/write its content
  # - copy from a stream
  # - being initialized with a specified size

  def setup
    content = 'crispelle al miele'
    @buf = BtcProto::Buffer.new(content)
    files = ['version.bin','inv.bin']
    @io = File.open(File.join(fixture_path, files.last),'rb')
  end

  def test_rewind_buffers_initialized_with_size
    skip
    content = 'arancino al sugo'
    buf = BtcProto::Buffer.of_size(content.size) do
      write_fixed_size_string(content)
    end
    assert_equal 0, buf.position
  end

  def test_binary_module_is_included
    assert BtcProto::Buffer.included_modules.include?(BtcProto::Binary)
  end

  def test_can_be_initialized_with_content
    assert_instance_of BtcProto::Buffer, @buf
  end

  def test_can_tell_the_current_buffer_position
    assert_instance_of Fixnum, @buf.position
  end

  def test_can_set_position
    assert_respond_to @buf, :position=
  end

  def test_can_seek_to_a_positive_value
    @buf.position = 2
    assert 2, @buf.position
  end

  def test_raises_an_error_if_a_negative_index_is_given
    assert_raises(ArgumentError) {@buf.position = -1}
  end

  def test_raises_an_error_if_an_out_of_bounds_index_is_given
    assert_raises(ArgumentError) {@buf.position = (@buf.size + 1)}
  end

  def test_can_read_a_null_terminated_string
    skip
    buf = BtcProto::Buffer.new("home sweet home\000")
    assert_equal 'home sweet home', buf.read_string
  end

  def test_can_write_a_null_terminated_string
    skip
    buf = BtcProto::Buffer.of_size(12) do
      write_string("o pigghilu!")
    end
    assert buf.content.each_char.detect {|char| char == "\000" }
  end

  def test_can_read_an_header_from_io
    buf = BtcProto::Buffer.new(@io.read(24))

    magic_number = buf.read_uint32_little
    assert BtcProto::lookup(:MAGIC).index(magic_number)

    command      = buf.read_null_padded_string(12).to_sym
    assert_equal :inv, command

    # length       = buf.read_int32_little
    # assert_equal length, 1715

    # checksum     = read_int32_little

  end
end

