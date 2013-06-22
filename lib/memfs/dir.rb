require 'memfs/filesystem_access'

module MemFs
  class Dir
    extend FilesystemAccess

    def self.chdir(path, &block)
      fs.chdir path, &block
      return 0
    end

    def self.getwd
      fs.getwd
    end

    def self.mkdir(path)
      fs.mkdir path
    end

    def self.entries(dirname, opts = {})
      fs.entries(dirname)
    end

    def self.rmdir(path)
      fs.rmdir path
    end

    def self.exists?(path)
      fs.directory?(path)
    end

    class << self
      alias :pwd :getwd
    end
  end
end