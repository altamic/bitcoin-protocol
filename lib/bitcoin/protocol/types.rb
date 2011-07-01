# Types module is able to handle:
#
#   - (de)serialization
#   - size calculation
#
# for the peculiar types introduced by Bitcoin. Mappings
# can be configured to provide serialization and size
# calculation functionality for external (vectors of)
# data structures introduced by the original protocol.
#
# The module is a mixin and assumes that the following
# methods:
#
#     read(n_bytes)
#     write(string)
#
# are available in the class/module, generally an IO object,
# extended by this module.
#
# Moreover serialization is assumed to be provided by
# the mapped object via load() and dump() methods.
#
# The set of recognized names are exposed by OBJECTS and
# COLLECTIONS constants.
#
# By including Binary mixin --and sharing its the very same
# interface, Types provide dynamically common methods
# for reading/writing from/to binary buffer streams.
# Read about Binary mixin for more information.
#
# Types performs operations recognized by the following
# grammar:
#
#  operations   ::= 'read' | 'write'
#  btc_encoding ::= 'encoded' | 'vector'
#  numbers      ::= 'bignum' | 'uint256_little'
#  strings      ::= 'string'
#

module Bitcoin::Protocol
  module Types
    include Binary

    OP_TYPE_RE = /(read|write)_(\w+)(_(vector))?/

    # Mapping between a type name and a class is configured externally
    # through an hash containing associations. The associated class is
    # supposed to provide load and dump methods. They are called by,
    # respectively, read_encoded_object and write_encoded_object.
    class << self
      def mappings()
        @@mappings
      end

      def mappings=(hash={})
        @@mappings = hash
        build_mapped_methods!
      end

      def valid(mappings, &block)
        raise ArgumentError if not mappings.kind_of?(Hash)
        validate = lambda { |o| [:load, :dump].each { |m| o.respond_to? m } }
        mappings.each_pair do |type, obj|
          yield(type, obj) if validate.call(obj)
        end
      end

      def blank(op, type)
        ["#{op}_#{type}", "#{op}_#{type}_vector"].map(&:to_sym).each do |m|
          undef_method(m) if defined? m
        end
      end

      def build_mapped_methods!
        valid(@@mappings) do |type, obj|
          [:read, :write].each do |op|
            # blank(op, type)
            case op
            when :read then
              define_method "read_#{type}".to_sym do
                read_encoded_object(type)
              end

              define_method "read_#{type}_vector".to_sym do
                read_encoded_object_vector(type)
              end
            when :write then
              define_method "write_#{type}".to_sym do |buf|
                write_encoded_object(type)
              end
              define_method "write_#{type}_vector".to_sym do |buf|
                write_encoded_object_vector(type)
              end
            end
          end
        end
      end
    end

    # NOTE: given the fact that messages above 50KB in size are invalid,
    # the standard mechanism for de/encoding size could be reviewed.
    # Likely, a uniform 16 bits Pascal string may manage messages up to 65KB;
    # compression mechanisms could be discussed whether the need arises.
    def read_encoded_size
      code = read_uint8
      case code
      when 253 then size_of(:uint16) + read_uint16_little  # upto ~65KB   (80%)
      when 254 then size_of(:uint32) + read_uint32_little  # upto ~4GB      (!)
      when 255 then sise_of(:uint64) + read_uint64_little  # upto ~1.8e9GB (!!)
      else
        code # size ≤ 252 bytes (happens 20%)
      end
    end

    # TODO: separate into size and string
    def write_encoded_size(size)
      raise ArgumentError if not size.kind_of? Integer
      case
      when (1 < size and size < 252) then
        write_uint8(size)
      when (253 < size and size < 0xFFFF) then
        write_uint8(253)
        write_uint16_little(size)
      when (0x10000 < size and size < 0xFFFFFFFF) then
        write_uint8(254)
        write_uint32_little(size)
      when (0x100000000 < size and size < 0xFFFFFFFFFFFFFFFF) then
        write_uint8(255)
        write_uint64_little(size)
      end
      size
    end

    def write_encoded_string(content)
      raise ArgumentError, 'string required' if not content.kind_of? String
      write_encoded_size(content.size)
      write_fixed_size_string(content) # expected from the public interface
    end

    def read_encoded_string
      # buffer position goes forward by the read_encoded_size
      read_string(:size => read_encoded_size)
    end

    def read_string(:size = nil)
      
    end

    alias :read_bignum  :read_uint256_little
    alias :write_bignum :write_uint256_little

    def read_encoded_bignum_vector
      result = []
      read_encoded_size.times do
        result.push(read_bignum)
      end
      result
    end

    def write_encoded_bignum_vector(bignum_array)
      raise ArgumentError, 'Array required' if not bignum_array.respond_to? :each
      write_encoded_size(bignum_array.size)
      bignum_array.each do |bignum|
        raise ArgumentError if not bignum.kind_of? Integer
        write_bignum(bignum)
      end
    end

    # def uint256_from_compact(c):
    # nbytes = (c >> 24) & 0xFF
    # v = (c & 0xFFFFFFL) << (8 * (nbytes - 3))
    # return vv
    def read_compact_target
      bits   = read_uint32_little
      bytes  = (bits >> 24) & 0xFF
      bignum = (bits & 0xFFFFFF) << (8 * (bytes - 3))
      bignum
    end

    def write_compact_target(bignum)
    end

    def read_encoded_object(type)
      fail "Unknown #{type} type" if not @@mappings.keys.include?(type)
      @@mappings[type].load(self)
    end

    def read_encoded_object_vector(type)
      fail "Unknown #{type} type" if not @@mappings.keys.include?(type)
      result = []
      read_encoded_size.times do
        result.push(read_encoded_object(type)) # read op of the given type
      end
      result
    end

    # private :read_encoded_object, :read_encoded_object_vector

    def write_encoded_object(type = :inventory)
      fail "Unknown #{type} type" if not @@mappings.keys.include?(type)
      @@mappings[type].dump(self)
    end

    def write_encoded_object_vector(type = :inventory)
      fail "Unknown #{type} type" if not @@mappings.keys.include?(type)
      read_encoded_size.times do
        write_encoded_object(type)
      end
    end

    # private :write_encoded_object, :write_encoded_object

    def read_uint256_vector
    end
  end
end

