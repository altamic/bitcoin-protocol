module Bitcoin
  module Protocol
    module Serializable
      ## who includes me must have the following
      # class variables:
      # @@fields
      # @@types
      # @@defaults

      def self.included(receiver)
        # receiver.extend self
        receiver.send :include, self
      end


      # receives the content
      def load(content)
        buf = BtcProto::Buffer.new(content)
        attributes.each do |a|
          puts "buf.read_#{types[a]}"
        end
      end

      def dump
        v = ''
        attributes.each do |a|
          puts "\":write_#{types[a]}\" (#{a}) #{BtcProto::Type.size(types[a])}"
        end
      end

      # alias :load :parse
    end
  end
end
