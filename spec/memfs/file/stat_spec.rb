require 'spec_helper'

module MemFs
  describe File::Stat do
    describe '.new' do
      context "when optional follow_symlink argument is set to true" do
        it "raises an error if the end-of-links-chain target doesn't exist" do
          fs.symlink('/test-file', '/test-link')
          expect { File::Stat.new('/test-link', true) }.to raise_error(Errno::ENOENT)
        end
      end
    end

    describe '#entry' do
      it "returns the comcerned entry" do
        entry = fs.touch('/test-file')
        stat = File::Stat.new('/test-file')
        stat.entry.should be_a(Fake::File)
      end
    end

    describe '#symlink?' do
      it "returns true if the entry is a symlink" do
        fs.touch('/test-file')
        fs.symlink('/test-file', '/test-link')
        File::Stat.new('/test-link').symlink?.should be_true
      end

      it "returns false if the entry is not a symlink" do
        fs.touch('/test-file')
        File::Stat.new('/test-file').symlink?.should be_false
      end
    end

    describe '#directory?' do
      before :each do
        fs.mkdir('/test')
        fs.touch('/test-file')
        fs.symlink('/test', '/link-to-dir')
        fs.symlink('/test-file', '/link-to-file')
      end

      it "returns true if the entry is a directory" do
        File::Stat.new('/test').should be_directory
      end

      it "returns false if the entry is not a directory" do
        File::Stat.new('/test-file').should_not be_directory
      end

      context "when the entry is a symlink" do
        context "and the optional follow_symlink argument is true" do
          it "returns true if the last target of the link chain is a directory" do
            File::Stat.new('/link-to-dir', true).should be_directory
          end

          it "returns false if the last target of the link chain is not a directory" do
            File::Stat.new('/link-to-file', true).should_not be_directory
          end
        end

        context "and the optional follow_symlink argument is false" do
          it "returns false if the last target of the link chain is a directory" do
            File::Stat.new('/link-to-dir', false).should_not be_directory
          end

          it "returns false if the last target of the link chain is not a directory" do
            File::Stat.new('/link-to-file', false).should_not be_directory
          end
        end
      end
    end

    describe '#mode' do
      it "returns an integer representing the permission bits of stat" do
        fs.touch('/test-file')
        fs.chmod(0777, '/test-file')
        File::Stat.new('/test-file').mode.should be(0100777)
      end
    end

    describe '#atime' do
      let(:time) { Time.now - 500000 }

      it "returns the access time of the entry" do
        fs.touch('/test-file')
        entry = fs.find!('/test-file')
        entry.atime = time
        File::Stat.new('/test-file').atime.should == time
      end

      context "when the entry is a symlink" do
        context "and the optional follow_symlink argument is true" do
          it "returns the access time of the last target of the link chain" do
            fs.touch('/test-file')
            entry = fs.find!('/test-file')
            entry.atime = time
            fs.symlink('/test-file', '/test-link')
            File::Stat.new('/test-link', true).atime.should == time
          end
        end

        context "and the optional follow_symlink argument is false" do
          it "returns the access time of the symlink itself" do
            fs.touch('/test-file')
            entry = fs.find!('/test-file')
            entry.atime = time
            fs.symlink('/test-file', '/test-link')
            File::Stat.new('/test-link').atime.should_not == time
          end
        end
      end
    end

    describe "#uid" do
      it "returns the user id of the named entry" do
        fs.touch('/test-file')
        fs.chown(42, nil, '/test-file')
        File::Stat.new('/test-file').uid.should be(42)
      end
    end

    describe "#gid" do
      it "returns the group id of the named entry" do
        fs.touch('/test-file')
        fs.chown(nil, 42, '/test-file')
        File::Stat.new('/test-file').gid.should be(42)
      end
    end

    describe "#blksize" do
      it "returns the block size of the file" do
        fs.touch('/test-file')
        File::Stat.new('/test-file').blksize.should be(4096)
      end
    end

    describe "#file?" do
      it "returns true if the entry is a regular file" do
        fs.touch('/test-file')
        File.stat('/test-file').should be_file
      end

      it "returns false if the entry is not a regular file" do
        fs.mkdir('/test-dir')
        File.stat('/test-dir').should_not be_file
      end

      context "when the entry is a symlink" do
        it "returns true if its target is a regular file" do
          fs.touch('/test-file')
          fs.symlink('/test-file', '/test-link')
          expect(File.stat('/test-link')).to be_file
        end

        it "returns false if its target is not a regular file" do
          fs.mkdir('/test-dir')
          fs.symlink('/test-dir', '/test-link')
          expect(File.stat('/test-link')).not_to be_file
        end
      end
    end

    describe "#world_writable?" do
      context "when +file_name+ is writable by others" do
        it "returns an integer representing the file permission bits of +file_name+" do
          fs.touch('/test-file')
          fs.chmod(0777, '/test-file')
          expect(File::Stat.new('/test-file')).to be_world_writable
        end
      end

      context "when +file_name+ is not writable by others" do
        it "returns nil" do
          fs.touch('/test-file')
          expect(File::Stat.new('/test-file')).not_to be_world_writable
        end
      end
    end

    describe "#sticky?" do
      it "returns true if the named file has the sticky bit set" do
        fs.touch('/test-file')
        fs.chmod(01777, '/test-file')
        expect(File::Stat.new('/test-file')).to be_sticky
      end

      it "returns false if the named file hasn't' the sticky bit set" do
        fs.touch('/test-file')
        expect(File::Stat.new('/test-file')).not_to be_sticky
      end
    end

    describe "#dev" do
      it "returns an integer representing the device on which stat resides" do
        fs.touch('/test-file')
        expect(File::Stat.new('/test-file').dev).to be_a(Fixnum)
      end
    end

    describe "#ino" do
      it "returns the inode number for stat." do
        fs.touch('/test-file')
        expect(File::Stat.new('/test-file').ino).to be_a(Fixnum)
      end
    end
  end
end