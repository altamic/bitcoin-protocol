module Bitcoin::Protocol
  # A buffer is an IO entity able to
  # - hold content
  # - perform seeks
  # - manage the seek position
  # - read/write its content
  # - copy from a stream
  # - being initialized with a specified size
  # - its length can't be modified after creation
  class Buffer
    include BtcProto::Types # namespaced?

    class Error < RuntimeError; end
    class EOF   < Error; end

    def self.of_size(size, &block)
      if (not size.kind_of?(Integer)) || (size < 0)
        raise ArgumentError, 'positive integer required'
      end
      new(0.chr * size, &block)
    end

    def initialize(content, &block)
      raise ArgumentError if not content.kind_of? String
      @content  = content
      @size     = content.size
      @position = 0
      instance_eval(&block) and rewind if block_given?
    end

    def size
      @size
    end

    def position
      @position
    end

    def position=(new_pos)
      raise ArgumentError if new_pos < 0 or new_pos > size
      @position = new_pos
    end

    def rewind
      @position = 0
      self
    end

    def at_end?
      position.equals?(size)
    end

    def content
      @content
    end

    def read(n)
      raise EOF, 'cannot read beyond the end of buffer' if position + n > size
      str = @content[@position, n]
      @position += n
      str
    end

    def copy_from_stream(stream, n)
      raise ArgumentError if n < 0
      while n > 0
        str = stream.read(n) 
        write(str)
        n -= str.size
      end
      raise if n < 0
    end

    def write(str)
      sz = str.size
      raise EOF, 'cannot write beyond the end of buffer' if @position + sz > @size
      @content[@position, sz] = str
      @position += sz
      self
    end

    # read till the end of the buffer
    def read_rest
      read(self.size-@position)
    end
  end

# needs Binary module
  autoload_all 'bitcoin/message',
               :Binary => 'binary'

  register_lookup_modules :binary  => :Binary
end

