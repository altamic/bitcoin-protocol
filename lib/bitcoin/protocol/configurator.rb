require 'bitcoin/utils'

module Bitcoin::Protocol
  #  This file is concerned with the responsibility
  #  of assembling pieces of information for the
  #  Bitcoin protocol. Such information is separated
  #  into constants, types and messages.
  #
  #  The protocol configuration itself is expressed in
  #  the form of an internal DSL in the configuration.rb
  #  file.
  extend self
  include Bitcoin::Utils

  def configure(&block)
    module_eval(&block)
  end

  # hash containing structural information about protocol's
  # constants in the following form:
  # :CONSTANT_1 => value
  # :CONSTANT_2 => 'string'
  # :CONSTANT_3 => lambda { Time.now.to_i }
  # :CONSTANT_4 => { :key_1 => 'value_1', ... }
  # ...
  # :CONSTANT_n => ...
  def consts
    @@constants ||= Hash.new
  end

  # hash containing structural information about protocol's
  # messages in the following form:
  #
  # :classes => {:msg_1 => Class_1, ..., :msg_n => Class_N}
  # :aliases => {:alias_1 => :msg_1, ..., alias_n => :msg_n}
  # :msg_1 => {
  #   :attributes = %w[attr_1 ... attr_n]
  #   attr_1  => { :default => nil, :type => nil }
  #   ...
  #   attr_n => { :default => nil, :type => nil }
  # }
  # ...
  # :msg_n => {
  #    ...
  # }
  def messages
    @@messages ||= Hash.new.merge!(:aliases => {}, :classes => {})
  end

  # hash containing structural information about protocol's
  # types in the following form:
  #
  # :classes => {:type_1 => Class_1, ..., :type_n => Class_N}
  # :type_1  => {
  #   :struct => %w[name_1, ..., name_n]
  #   name_1 => { :type => type_1, :default => value_1 }
  #   ...
  #   name_n => { :type => type_n, :default => value_n }
  # }
  # ...
  def types
    @@types ||= Hash.new.merge!(:classes => {})
  end

  def warn_if_already_present(name, object)
    warn "already registered object #{name} " +
         "is going to be modified" if object.has_key? name
  end

  def register_constant(name, value)
    warn_if_already_present(name, consts)
    Definition.new(:constant, name, :value => value)
  end

  def register_type(name, options={}, &block)
    warn_if_already_present(name, types)
    if block_given?
      block.call(Definition.new(:type, name, options))
    else
      Definition.new(:type, name, options)
    end
  end

  def register_message(name, options={}, &block)
    warn_if_already_present(name, messages)
    if block_given?
      block.call(Definition.new(:message, name, options))
    else
      Definition.new(:message, name, options)
    end
  end

  def has_const?(name)
    consts.keys.include?(name)
  end

  def has_type?(name)
    types.keys.include?(name)
  end

  def has_message?(name)
    ((messages.keys - [:aliases, :classes]) +
      messages[:aliases].keys).include?(name)
  end

  def has_message_alias?(name)
    (messages[:aliases].keys).include?(name)
  end

  def proper_message_names
    messages.keys - [:aliases, :classes]
  end

  def proper_type_names
    types.keys - [:classes]
  end

  def type_classes
    types[:classes]
  end

  def aliases
    messages[:aliases]
  end

  def current_network
    @@default_network ||= lookup(:DEFAULT_NETWORK)
  end

  def current_network=(value)
    @@default_network = value if lookup(:MAGIC).keys.include?(value)
  end

  def register_sequence(name, options)
  end

  def configure!
    build_types
    build_messages
  end

  # Here goes the logic for protocol types. Basically
  # involves definition of each class with its own
  # attributes types and default values, load and
  # dump methods.
  #
  def build_types
    proper_type_names.each do |type|
      klass        = type.to_s.camelize
      struct_attrs = struct_attributes_for(:type, type)
      attributes   =        attributes_for(:type, type)
      defaults     =          defaults_for(:type, type)
      types        =             types_for(:type, type)

      self.module_eval <<-EVAL, __FILE__, __LINE__ + 1
      class #{klass} < Struct.new('#{klass}'#{struct_attrs})
        def attributes()  @@attributes = #{attributes.inspect} end
        def defaults()    @@defaults   = #{defaults.inspect} end

        def initialize(hash={}, &block)
          super
          attributes.each do |attribute|
            send("\#{attribute}=", Bitcoin::Protocol.lookup(defaults[attribute]))
          end
          hash.keys.each do |key|
            send("\#{key}=", hash[key]) if self.respond_to? key
          end
          instance_eval(&block) if block_given?
        end

        # evaluated after initialization so it can reflect upon its own values
        def types()       @@types      = #{types.inspect} end

        # obtain an object
        def self.load(buf)
          buf.read_encoded_size # TODO: actually use it
          obj = new
          obj.attributes.each do |a|
            attr_writer = "\#{a}="
            buffer_method = "read_\#{obj.types[a]}".to_sym
            obj.send(attr_writer, buf.send(buffer_method))
          end
          obj
        end

        # return a string representation of the object
        def dump
          str = ""
          attributes.each do |a|
            str + "write_\#{types[a]}="
            buffer_method = "write_\#{types[a]}".to_sym
            send(attr_writer, buf.send(buffer_method))
          end
        end
      end
      EVAL

      type_classes.merge!(type => Bitcoin::Protocol.const_get(klass))
    end

    Types.mappings = type_classes
  end

  # Here goes the logic for protocol messages. Basically
  # involves definition of each class with its own
  # attributes types and default values, load and
  # dump methods.
  #
  def build_messages
    proper_message_names.each do |message|
      klass        = message.to_s.camelize
      attributes   = attributes_for(:message, message)
      struct_attrs = struct_attributes_for(:message, message)
      defaults     = defaults_for(:message,   message)
      types        = types_for(:message,      message)


      self.module_eval <<-EVAL, __FILE__, __LINE__ + 1
      class #{klass} < Struct.new('#{klass}'#{struct_attrs})
        def attributes()  @@attributes = #{attributes.inspect} end
        def defaults()    @@defaults   = #{defaults.inspect} end

        def initialize(hash={}, &block)
          # super
          attributes.each do |attribute|
            send("\#{attribute}=", Bitcoin::Protocol.lookup(defaults[attribute]))
          end
          hash.keys.each do |key|
            send("\#{key}=", hash[key]) if self.respond_to? key
          end
          instance_eval(&block) if block_given?
        end

        # evaluated after initialization so it can reflect upon its own values
        def types()       @@types      = #{types.inspect} end

        private
        def init(attrs, defaults)
          attrs.each do |attrib|
            send("\#{attrib}=", Bitcoin::Protocol.lookup(defaults[attrib]))
          end
        end
      end
      EVAL

      self.messages[:classes].
        merge!(message => Bitcoin::Protocol.const_get(klass))
    end

    # add logic for marshalling i.e. load and dump
    # each type should be able to determine its size

    # associate class with names
    # new_item = { :class => command }
    # properties.assoc(message).push(new_item)
  end

  # lookup returns the value of the constant passed as a parameter.
  # A constant can also be a Proc object with no parameters.
  def lookup(const_key)
    case
    when const_key.kind_of?(Numeric) then const_key
    when const_key.kind_of?(String)  then const_key
    when const_key.kind_of?(Symbol)  then
      if has_const?(const_key)
        value = consts[const_key]
        value.is_a?(Proc) ? value.call : value
      elsif proper_type_names.include?(const_key)
        class_for(:type, const_key).new
      elsif const_key.to_s =~ /vector$/
        Array.new
      end
    when const_key.kind_of?(Array)  then
      if has_const?(const_key.first) and const_key.size == 2
        key, value =[const_key.first, const_key.last]
        consts[key][value]
      end
    when const_key.kind_of?(Proc) then
      const_key.call
    end
  end

  def attributes_for(object, name)
    case object
    when :type
      types[name][:struct] if has_type?(name)
    when :message
      if has_message?(name)
        if has_message_alias?(name)
          aliases[:inventory][name][:attributes]
        else
          messages[name][:attributes]
        end
      end
    end
  end

  def types_for(object, name)
    case object
    when :type
      if has_type?(name)
        attributes_for(object, name).inject({}) do |defaults, attribute|
          defaults.merge!(attribute => types[name][attribute][:type])
        end
      end
    when :message
      if has_message?(name)
        attributes_for(object, name).inject({}) do |defaults, attribute|
          defaults.merge!(attribute => messages[name][attribute][:type])
        end
      end
    end
  end

  def defaults_for(object, name)
    case object
    when :type
      attributes_for(object, name).inject({}) do |defaults, attribute|
        defaults.merge!(attribute => types[name][attribute][:default])
      end
    when :message
      attributes_for(object, name).inject({}) do |defaults, attribute|
        defaults.merge!(attribute => messages[name][attribute][:default])
      end
    end
  end

  def struct_attributes_for(object, name)
    attributes  = attributes_for(object, name)
    if attributes.any?
      attributes.map{|a| ":#{a}"}.unshift(' ').join(', ')
    else
      ''
    end
  end

  def class_for(object, name)
    case object
    when :type    then types[:classes][name]
    when :message then messages[:classes][name]
    end
  end

  def alias_for(message)
    aliases[message] if aliases.has_key?(message)
  end

  class Definition
    PROTOCOL  = Bitcoin::Protocol
    RESOURCE  = {
      :integer  => '((uint|int)(8|16|32|64|128)_?(big|little|network)?)',
      :ipv6     => '(uint128_network|ipv6)',
      :bignum   => '(uint256_little|bignum)',
      :bitcoin  => '(string|address|block_locator|inventory|transaction|tx_input|tx_output|out_point|compact_target)'
    }
    COLLECTION = '(vector|collection)'

    KNOWN = Regexp::compile("((#{RESOURCE.values.join('|')})(_#{COLLECTION})?)")

    def initialize(object, name, options={})
      @object, @name, @options = object, name, options
      case @object
      when :constant  then
        # :CONSTANT_1 => value
        PROTOCOL.consts[@name] = options[:value]
      when :type      then
        if not PROTOCOL.types.has_key? @name
          # :type_m  =>  {
          #   :struct => %w[name_1, ..., name_n]
          #   ...
          PROTOCOL.types[@name] = { :struct => [] }
        end
      when :message   then
        if options[:alias]
        # :aliases  => {:alias_1 => :msg_1, ..., alias_n => :msg_n}
          PROTOCOL.messages[:aliases].merge!(options[:alias] => @name)
        end
        if not PROTOCOL.messages.has_key? @name
          # :msg_1 => {
          #   :attributes = %w[attr_1 ... attr_n]
          #   ...
          PROTOCOL.messages[@name] = { :attributes => [] }
        end
      end
    end

    def add(field_name, opt={})
      case @object
      when :type then
        PROTOCOL.types[@name][:struct].push(field_name)
        PROTOCOL.types[@name][field_name]    = opt
      when :message then
        PROTOCOL.messages[@name][:attributes].push(field_name)
        PROTOCOL.messages[@name][field_name] = opt
      end
    end

    def method_missing(field_type, field_name, opts={}, &block)
      if field_type.to_s =~ KNOWN
        resource = Regexp.last_match[0]
        add(field_name, {:type => resource.to_sym, :default => opts[:default]})
      elsif field_type.to_s =~ /^((\w)(_\w)+)$/
        resource = Regexp.last_match[1]
        add(field_name, {:type => resource.to_sym, :default => opts[:default]})
      else
        super
      end
    end
  end
end

