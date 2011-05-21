require 'helper'

#
# a message should be initialized with an Hash
#


class TestMessage < Bitcoin::TestCase
  def setup
    # TODO: collect more binary messages and generalize
    files = ['version.bin','inv.bin']
    @io = File.open(File.join(fixture_path, files.first),'rb')
  end

  def test_read_message_header
    # assert_instance_of BtcProto::Inv, BtcProto::Message.read(@io)
  end

  def test_has_a_proper_header
  end

  # def test_read_instantiates_a_command
    # @io.seek(0)
    # result = BtcMsg.read(@io)
    # klazz  = BtcProto
    # assert_instance_of BtcProto::Message, result
  # end

  # def test_read_class_method
    # @io.seek(0)
    # assert_no_exception BtcProto::Message.read(@io)
  # end

  # def test_deserialize_a_la_bitcoin
    # string = BtcProto::Message.new
    # @io.seek(0x10)
    # assert_equal string.size, @io_size
    # assert_equal 0x55, string.deserialize(@io).size
  # end
end

