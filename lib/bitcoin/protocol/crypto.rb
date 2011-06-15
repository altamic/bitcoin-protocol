require 'digest/sha2'

module Bitcoin::Protocol
  #
  #
  #
  module Crypto
    extend self

    def doubleSHA256(string)
      Digest::SHA256.digest(Digest::SHA256.digest(string))
    end

    def ripe160_with_sha256(string)
      ripemd160 = `echo #{string} | openssl dgst -ripemd160 -binary` 
      Digest::SHA256.digest(ripemd160).unpack('C*')
    end

    def base58encode(number)
      return nil if not number.is_a? Integer
      base         = 58
      coefficients = []
      while(number.divmod(base).first >= base ) do
        coefficients.push(number.divmod(base).last)
        number = number.divmod(base).first
      end
      coefficients.push(*number.divmod(base).reverse).reverse!

      alphabeth = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'.split(//)
      result = []
      coefficients.each {|coeff| result.push(alphabeth[coeff]) }
      result.join
    end

    def base58decode(string)
      alphabeth = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'.split(//)
      base      = 58
      coefficients = []
      string.each_char do |char|
       coefficients.push(alphabeth.index(char))
      end
      return nil if coefficients.any?{|obj| obj.nil?}
      result = 0
      coefficients.reverse.each_with_index do |coeff, power|
        result += coeff * base**power
      end
      result
    end

    def generate_key_pair
      raise NotImplementedError #TODO
    end
  end
end

