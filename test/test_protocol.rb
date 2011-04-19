require 'helper'

class TestProtocol < Bitcoin::TestCase
  def test_version
    version_match = /\d+\.\d+\.\d+/
    assert_match version_match, BtcProto::VERSION
  end

  def has_abbreviated_constant
    assert defined?(BtcProto)
  end

  def test_has_messages_constant
    assert BtcProto.consts
  end

  # test lookup?

  def test_responds_to_class_for
    assert BtcProto.respond_to? :class_for
  end

  def test_method_class_for_has_arity_of_one
    assert BtcProto.method(:class_for).arity, 2
  end

  def test_has_proper_message_names
    assert_kind_of Array, BtcProto.proper_message_names
  end

  def test_has_proper_type_name
    assert_kind_of Array, BtcProto.proper_type_names
  end
end

BtcProto.proper_message_names.each do |command|
  TestProtocol.class_eval do
    test_msg_known = "test_protocol_knows_about_#{command}_message"
    define_method test_msg_known do
      assert BtcProto.messages[:classes].keys.include?(command)
    end

    test_msg_handled = "test_there_is_a_class_handling_#{command}_message"
    define_method test_msg_handled do
      assert BtcProto.class_for(:message, command).kind_of? Class
    end
  end
end


BtcProto.proper_type_names.each do |type|
  TestProtocol.class_eval do
    test_type_known = "test_protocol_knows_about_#{type}_type"
    define_method test_type_known do
      assert BtcProto.types[:classes].keys.include?(type)
    end

    test_type_handled = "test_there_is_a_class_handling_#{type}_message"
    define_method test_type_handled do
      assert BtcProto.class_for(:type, type).kind_of? Class
    end
  end
end


