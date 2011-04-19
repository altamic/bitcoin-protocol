require 'digest/sha2'

module Bitcoin::Protocol
  #
  #
  #
  module Crypto
    def doubleSHA256(string)
      Digest::SHA256.digest(Digest::SHA256.digest(string))
    end

    def ripe160_with_sha256(string)
      ripemd160 = `echo #{string} | openssl dgst -ripemd160 -binary` 
      Digest::SHA256.digest(ripemd160).unpack('C*')
    end

    def base58encode(string)
      raise NotImplementedError #TODO
    end

    def base58decode(string)
      raise NotImplementedError #TODO
    end

    def generate_key_pair
      raise NotImplementedError #TODO
    end
  end
end

