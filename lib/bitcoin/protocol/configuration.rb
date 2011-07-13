# The semantic model of Bitcoin protocol is configured
# here using public APIs exposed in configurator.rb

Bitcoin::Protocol.configure do
  # Constants
  register_constant :MESSAGE_SIZE_LIMIT, 50_000
  register_constant :VERSION,     318
  register_constant :SUB_VERSION, '.1'

  register_constant :DEFAULT_NETWORK, :production

  register_constant :MAGIC,    :production   => 0xF9BEB4D9,
                               :test         => 0xDAB5BFFA
  register_constant :SERVICES, :node_network => 1

  register_constant :UNIX_TIMESTAMP, lambda { Time.now.to_i }
  register_constant :RANDOM_64BITS,  lambda { rand(2**64) }
  register_constant :RANDOM_32BITS,  lambda { rand(2**32) }


  # Types
  register_type :address do |t|
    t.uint64_little   :services,   :default => [:SERVICES, :node_network]
    t.uint128_network :ip_address, :default => 0xFFFF00000000
    t.uint16_network  :port,       :default => 0
  end

  register_type :out_point do |t|
    t.uint256_little :hash, :default => 0
    t.uint32_little  :size, :default => 0
  end

  register_type :tx_input do |t|
    t.out_point      :previous
    t.encoded_string :script_signature, :default => ""
    t.uint32_little  :sequence,         :default => 0
  end

  register_type :tx_output do |t|
    t.int64_little    :value,             :default => 0
    t.encoded_string  :script_public_key, :default => ""
  end

  register_type :transaction do |t|
    t.int32_little     :version, :default => :VERSION
    t.tx_input_vector  :inputs,  :default => []
    t.tx_output_vector :outputs, :default => []
    t.uint32_little    :lock_time
  end

  register_constant :INVENTORY_TYPES, {:error => 0, :tx => 1, :block => 2}

    register_type :inventory do |t|
    t.int32_little   :type, :default => [:INVENTORY_TYPES, :error]
    t.uint256_little :hash, :default => 0
  end

  register_type :block_locator do |t|
    t.int32_little          :version,           :default => :VERSION
    t.uint256_little_vector :available_hashes
  end

  # Messages
  register_message :version do |m|
    m.uint32_little  :version,         :default => :VERSION
    m.uint64_little  :services,        :default => [:SERVICES, :node_network]
    m.int64_little   :time,            :default => :UNIX_TIMESTAMP
    m.address        :origin,          :default => :address
    m.address        :destination,     :default => :address
    m.int64_little   :nonce,           :default => :RANDOM_64BITS
    m.encoded_string :sub_version,     :default => :SUB_VERSION, :size => 4
    m.int32_little   :starting_height, :default => nil
  end

  register_message :block do |m|
    m.int32_little        :version,             :default => :VERSION
    m.uint256_little      :hash_previous_block
    m.uint256_little      :hash_merkle_root
    m.uint32_little       :time,                :default => 0
    m.compact_target      :bits,                :default => 0
    m.uint32_little       :nonce,               :default => :RANDOM_32BITS
    m.transaction_vector  :transactions,        :default => []
  end

  register_message :tx, :alias => :transaction do |m|
    m.transaction   :transaction
  end

  register_message :verack, :alias => :version_ack

  register_message :addr, :alias => :addresses, :size_limit => 1000 do |m|
    m.address_vector :addresses, :default => []
  end

  register_message :inv, :alias => :inventory, :size_limit => true do |m|
    m.inventory_vector  :inventory, :default => []
  end

  register_message :getdata, :alias => :get_data, :size_limit => true do |m|
    m.inventory_vector  :inventory, :default => []
  end

  register_message :getblocks, :alias => :get_blocks do |m|
    m.block_locator  :locator
    m.uint256_little :hash_stop
  end

  register_message :getaddr, :alias => :get_addresses

  register_message :checkorder, :alias => :check_order

  register_message :submitorder, :alias => :submit_order

  register_message :reply

  register_message :ping

  register_message :alert

  register_sequence :initialize,        :request => :version,   :response => :verack
  register_sequence :identificate_peer, :request => :getaddr,   :response => :addr
  register_sequence :bootstrap_blocks,  :request => :getblocks, :response => :inv
end

