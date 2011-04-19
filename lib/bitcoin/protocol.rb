require 'bitcoin/protocol/configurator'
require 'bitcoin/protocol/configuration'

module Bitcoin
  module Protocol
    VERSION = '0.0.3'

    extend AutoloadHelper

    autoload_all 'bitcoin/protocol',
      :Binary         => 'binary',
      :Types          => 'types',
      :Buffer         => 'buffer',
      :Utils          => 'utils',
      :Serializable   => 'serializable',
      :Message        => 'message',
      :Crypto         => 'crypto',
      :Configurator   => 'configurator'


      register_lookup_modules \
      :binary         => :Binary,
      :types          => :Types,
      :buffer         => :Buffer,
      :utils          => :Utils,
      :serializable   => :Serializable,
      :message        => :Message,
      :crypto         => :Crypto,
      :configurator   => :Configurator

  end
end

Bitcoin::Protocol.configure!

BtcProto = Bitcoin::Protocol

