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
    # In this module we define the common behaviour
    # for a protocol message
    #
    # - read a message from a stream
    # - returns a particular message when found
    # - a sequence of fields as class variables
    # - hash of fields containing a serialization
    #   type and a default value

    extend Crypto

    class LoadError  ; end
    class DumpError  ; end
    class ValueNotAllowed < RuntimeError; end

    class BadMagicNumber < ValueNotAllowed; end
    class UnknownCommand < ValueNotAllowed; end
    class BadPayload     < ValueNotAllowed; end
    class BadLength      < ValueNotAllowed; end

    attr_reader :magic_number, :command, :length, :checksum, :payload

    # adds these to the singleton through configuration
    @@attributes = [ :magic_number, :command, :length, :checksum, :payload ]
    @@defaults   = { :magic_number => [:MAGIC, BtcProto.current_network],
                     :command      => :verack,
                     :length       => 0,
                     :checksum     => 0,
                     :payload      => 0 }
    @@types      = { :magic_number => :uint32_little,
                     :command      => :null_padded_string_of_12_bytes,
                     :length       => :int32_little,
                     :checksum     => :int32_little,
                     :payload      => [:fixed_string, :length] }

    # it should define the header size
    def self.read(stream)
      header       = Buffer.new(stream.read_exactly(4+12+4+4))
      magic_number = header.read_uint32_little
      fail BadMagicNumber if not BtcProto.lookup(:MAGIC).values.include?(magic_number)
      network      = NETWORKS.index(magic_number)
      command      = header.read_fixed_size_string(12,:padding => 0.chr).to_sym
      fail UnknownCommand if not BtcProto.proper_message_names.include?(command)
      length       = header.read_int32_little
      checksum     = header.read_int32_little
      payload = Buffer.new(stream.read_exactly(length)).content # possibly avoid Buffer
      fail BadPaylod if not valid_payload?(payload, [checksum].pack('V'))

      BtcProto.class_for(command).load(payload)
    end

    def self.valid_payload?(content, checksum)
      doubleSHA256(content)[0..3] == checksum
    end

    def self.compute_checksum_for(content)
      doubleSHA256(content)[0..3]
    end

    # def magic_number(network)
    # return nil if not NETWORKS.keys.include?(network)
    # NETWORKS[network]
    # end

    # check if buffer size is ok before
    def self.load(buffer)
      marshal(:read, buffer)
    end

    alias :restore :load

    def self.dump(buffer)
      # check if buffer size is ok before
      marshal(:write, buffer)
    end

    def marshal(op, buffer)
      case op
      when :read
        attributes.each do |attribute|
          binary_op = "#{read}_#{types[attribute]}".to_sym
          self.send("#{attribute}=", buffer.send(binary_op))
        end
      when :write
        attributes.each do |attribute|
          binary_op = "#{write}_#{types[attribute]}".to_sym
          self.send("#{attribute}=", buffer.send(binary_op))
        end
      end
    end

    private :marshal

    def size
    end

    # compute_checksum
    def compute_checksum
    end
  end
end

BtcMsg = Bitcoin::Protocol::Message

