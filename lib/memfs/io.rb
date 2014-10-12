require 'forwardable'
require 'memfs/filesystem_access'

module MemFs
  module IO
    module ClassMethods
      def read(path, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options = { mode: File::RDONLY, encoding: nil, open_args: nil }.merge(options)
        open_args = options[:open_args] ||
                    [options[:mode], encoding: options[:encoding]]

        length, offset = args

        file = open(path, *open_args)
        file.seek(offset || 0)
        file.read(length)
      ensure
        file.close if file
      end
    end

    module InstanceMethods
      def close
        self.closed = true
      end

      def closed?
        closed
      end

      def external_encoding
        writable? ? @external_encoding : Encoding.default_external
      end

      def initialize(filename, mode = File::RDONLY, *perm_and_or_opt)
        opt = perm_and_or_opt.last.is_a?(Hash) ? perm_and_or_opt.pop : {}
        perm = perm_and_or_opt.shift
        if perm_and_or_opt.size > 0
          fail ArgumentError, 'wrong number of arguments (4 for 1..3)'
        end

        @path = filename
        @external_encoding = opt[:external_encoding] && Encoding.find(opt[:external_encoding])

        self.closed = false
        self.opening_mode = str_to_mode_int(mode)

        fs.touch(filename) if create_file?

        self.entry = fs.find(filename)

        entry.content.clear if truncate_file?
      end

      def each(sep = $/, &block)
        return to_enum(__callee__) unless block_given?
        fail IOError, 'not opened for reading' unless readable?
        content.each_line(sep) { |line| block.call(line) }
        self
      end

      def pos
        entry.pos
      end

      def puts(text)
        fail IOError, 'not opened for writing' unless writable?

        content.puts text
      end

      def read(length = nil, buffer = '')
        default = length ? nil : ''
        content.read(length, buffer) || default
      end

      def seek(amount, whence = ::IO::SEEK_SET)
        new_pos = case whence
                  when ::IO::SEEK_CUR then entry.pos + amount
                  when ::IO::SEEK_END then content.to_s.length + amount
                  when ::IO::SEEK_SET then amount
                  end

        fail Errno::EINVAL, path if new_pos.nil? || new_pos < 0

        entry.pos = new_pos
        0
      end

      def stat
        File.stat(path)
      end

      def write(string)
        fail IOError, 'not opened for writing' unless writable?

        content.write(string.to_s)
      end

      private

      attr_accessor :closed,
                    :entry,
                    :opening_mode

      attr_reader :path

      def content
        entry.content
      end

      def create_file?
        (opening_mode & File::CREAT).nonzero?
      end

      def readable?
        (opening_mode & File::RDWR).nonzero? ||
        (opening_mode | File::RDONLY).zero?
      end

      def str_to_mode_int(mode)
        return mode unless mode.is_a?(String)

        unless mode =~ /\A([rwa]\+?)([bt])?\z/
          fail ArgumentError, "invalid access mode #{mode}"
        end

        mode_str = $~[1]
        File::MODE_MAP[mode_str]
      end

      def truncate_file?
        (opening_mode & File::TRUNC).nonzero?
      end

      def writable?
        (opening_mode & File::WRONLY).nonzero? ||
        (opening_mode & File::RDWR).nonzero?
      end
    end
  end
end
