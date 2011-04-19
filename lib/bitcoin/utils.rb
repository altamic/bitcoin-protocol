module Bitcoin
  module Utils
    extend self

    def uint256_from_compact(c)
      # nbytes = (c >> 24) & 0xFF
      # v = (c & 0xFFFFFFL) << (8 * (nbytes - 3))
      # return v
    end

    def string_to_bignum
      # s = self.dup.rjust(32,'0')
      # r = 0
      # t = self[0..32].unpack("<IIIIIIII", s[:32])
      # 8.times {|i| r += t[i] << (i * 32)}
    end

    # def uint256_from_compact(c):
    # nbytes = (c >> 24) & 0xFF
    # v = (c & 0xFFFFFFL) << (8 * (nbytes - 3))
    # return v
    #
    def compact_target_to_bignum
    end

    # alias compact_target_to_bignum compact_target_to_uint256

    # def deser_vector(f, c):
    # r = []
    # for i in xrange(nit):
    # t = c()
    # t.deserialize(f)
    # r.append(t)
    # return r
    #
    def read_vector(opt = {:type => :address})
      result = []
      read_encoded_size.times do
        result.push(read_uint8)
      end
      result
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        lower_case_and_underscored_word.to_s[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end
  end
end

class String
  [:underscore, :camelize].each {|method| undef method if self.respond_to? method }

  def underscore
    Bitcoin::Utils.underscore(self)
  end

  def camelize
    Bitcoin::Utils.camelize(self)
  end

  def to_bignum
    Bitcoin::Utils.string_to_bignum(self)
  end

  alias_method(:to_uint256, :to_bignum)
end

