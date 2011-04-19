require 'helper'

# it should contain constants as an hash
# it should be able to lookup at constants: differentiate cases
# it should contain messages as an hash
# it should contain types as an hash

class TestConfigurator < Bitcoin::TestCase
  def setup
    @definition = BtcProto::Definition
  end

  def test_constant_definition
    pi = Math::PI
    @definition.new(:constant, :pi, :value => pi)
    assert BtcProto.consts.keys.include? :pi
    assert BtcProto.consts[:pi], pi
  end

  def test_type_definition_has_struct
    @definition.new(:type, :sample, {})
    assert BtcProto.types[:sample].has_key?(:struct)
  end

  # def setup
    # @line =' register_message :addr, :alias => :addresses, :size_limit => 1000 do |m|'
    # @messages_re = /register_message\s+:(\w+)\s*/
    # @aliases_re  = /#{@messages_re}\.*\s*,\s*:alias\s*=>\s*:(\w+[_\w+]*)/
    # @fields_re   = /d/
    # @configured_messages = fetch(:messages, :from => 'protocol/configuration.rb')
    # @configured_aliases  = fetch(:aliases)
    # @configured_fields   = fetch(:fields)

    # @messages_lines = fetch_lines_matching('register_message')
    # @fields_lines   = fetch_lines_matching('m.')
  # end

    # def test_messages_re
    # assert_match @messages_re, @line
  # end

  # def test_messages_re_match
    # @line =~ @messages_re
    # assert_equal Regexp.last_match[1], 'addr'
  # end

  # def test_aliases_re
    # assert_match @aliases_re, @line
  # end

  # def test_aliases_re_match
    # @line =~ @aliases_re
    # assert_equal Regexp.last_match[2], 'addresses' 
  # end

  # def test_aliases_re_match_with_underscore
    # line = '  register_message :getdata, :alias => :get_data, :size_limit => true'
    # line =~ @aliases_re
    # assert_equal Regexp.last_match[1], 'getdata'
    # assert_equal Regexp.last_match[2], 'get_data' 
  # end

  # def test_fields_re
  # end

  # def test_fields_re_match
  # end

  # private
  # def fetch_lines_matching(string, opt={:from => 'protocol/configuration.rb'})
    # rel_file_path = File.join(lib_path, opt[:from])

    # matching_lines = []
    # File.open(File.expand_path(rel_file_path)) do |f|
      # f.each_line do |line|
        # matching_lines.push(Regexp.last_match[1]) if line =~ /#{string}/
      # end
    # end
    # matching_lines
  # end

  # def fetch(element, opt={:from  => 'protocol/configuration.rb'})
    # rel_file_path = File.join(lib_path, opt[:from])

    # msg_re, match_idx = case element 
                        # when :messages then [@messages_re,   1  ]
                        # when :aliases  then [@aliases_re,    2  ]
                        # when :fields   then [@fields_re,   1..-1]
                        # else
                          # return nil
                        # end

    # configured_elements = []
    # File.open(File.expand_path(rel_file_path)) do |f|
      # f.each_line do |line|
        # configured_elements.push(Regexp.last_match[match_idx]) if line =~ msg_re
      # end
    # end
    # configured_elements
  # end
end
