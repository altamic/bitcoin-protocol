require 'helper'

class TestCrypto < Bitcoin::TestCase

  def test_base58encode
    number = 1231  # => 1231 = 21 * 58^1 + 13 * 58^0
    assert_equal "NE", BtcProto::Crypto.base58encode(number)

    number2 = 12310 # => 3 * 58^2 + 38 * 58^1 + 14 * 58^0
    assert_equal "4fF", BtcProto::Crypto.base58encode(number2)
  end

  def test_base58decode
    number = 1231  # => 21 * 58^1 + 13 * 58^0
    assert_equal 1231, BtcProto::Crypto.base58decode('NE')

    number = 12310 # => 3 * 58^2 + 38 * 58^1 + 14 * 58^0
    assert_equal 12310, BtcProto::Crypto.base58decode('4fF')   
  end
end
