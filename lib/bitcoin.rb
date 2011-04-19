$LOAD_PATH.unshift File.dirname(__FILE__)

module Bitcoin
  autoload(:Protocol,       'bitcoin/protocol')
  autoload(:AutoloadHelper, 'bitcoin/autoload_helper')
end

# preserve your fingertips
Btc = Bitcoin if not defined?(Btc)
