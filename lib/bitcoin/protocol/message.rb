class IO
  def read_exactly(n)
    buf = read(n)
    fail EOFError if buf == nil
    return buf if buf.size == n

    n -= buf.size

    while n > 0
      str = read(n)
      fail EOFError if str == nil
      buf << str
      n -= str.size
    end
    return buf
  end
end

module Bitcoin::Protocol
  module Message
    extend Crypto

    HEADER_SIZE = 24

    class ValueNotAllowed < RuntimeError; end
    class BadMagicNumber < ValueNotAllowed; end
    class UnknownCommand < ValueNotAllowed; end
    class BadPayload     < ValueNotAllowed; end
    class BadLength      < ValueNotAllowed; end

    attr_reader :magic_number, :command, :length, :checksum, :payload

    def self.write(stream, command)
      # send header
      stream.write_uint32_little(::BtcProto.current_network)
      stream.write_null_padded_string('verack', 12)

      # TODO: find size for any given command
      stream.write_int32_little(0)

      # TODO: determine dump representation for any given command
      stream.write_int32_little(compute_checksum_for(command.dump))

      # send command
      stream.write(Bitcoin::Protocol::Verack.dump)
    end

    def self.read(stream)
      header       = Buffer.new(stream.readn(HEADER_SIZE))
      magic_number = header.read_uint32_little
      fail BadMagicNumber if not BtcProto.lookup(:MAGIC).values.include?(magic_number)
      network      = BtcProto::lookup(:MAGIC).index(magic_number)
      command      = header.read_null_padded_string(12).to_sym
      fail UnknownCommand if not BtcProto.proper_message_names.include?(command)
      length       = header.read_int32_little
      checksum     = [header.read_int32_little].pack('V')
      payload      = Buffer.new(stream.read_exactly(length)).content
      fail BadPayload if not valid?(payload, checksum)

      BtcProto.class_for(:message, command).load(Buffer.new(payload))
    end

    # In this module we define the common behaviour for a protocol message
    #
    # - read a message from a stream
    # - returns a particular message when found
    # - a sequence of fields as class variables
    # - hash of fields containing a serialization
    #   type and a default value

    class LoadError  ; end
    class DumpError  ; end
    class ValueNotAllowed < RuntimeError; end
    # it should define the header size

    def self.valid?(payload, checksum)
      doubleSHA256(payload)[0..3] == checksum
    end

    def self.compute_checksum_for(content)
      doubleSHA256(content)[0..3]
    end

    # check if buffer size is ok before
    def self.load(buffer)
      marshal(:read, buffer)
    end

    alias :restore :load

    def self.name(command)
      command.class.to_s.underscore.split('/').last
    end

    def size(command)
      case command.class
      when BtcProto::Verack then 0
      when BtcProto::Ping   then 0
      when BtcProto::Reply  then 0
      when BtcProto::Alert  then 0
      when BtcProto::Getaddr then 0
      when BtcProto::Checkorder then 0
      when BtcProto::Submitorder then 0

      when BtcProto::Inv then n * (4 + 32) # inventory vectors
      when BtcProto::Getdata then n * (4 + 32) # inventory vectors

      when BtcProto::Getblocks then n * (4 + 32)  + 32

      when BtcProto::Addr then 
      when BtcProto::Version then 
      when BtcProto::Tx then  
      when BtcProto::Blocks then
        n = command.transactions.any? ? command.transactions.size : 0
        inputs = 0
        n.times do |i|
          inputs = command.transactions[i].inputs.size
          outputs = command.transactions[i].outputs.size
        end
        # n, j , k, l = 
        4 + 32 + 32 + 4 + 4 + 4 + txs * (4 + inputs*(32 + 4) + outputs * (8 + script_len) + 4)
      end
    end
  end
end

BtcMsg = Bitcoin::Protocol::Message

