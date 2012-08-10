require 'ffi'

module PosixSpawn
  extend FFI::Library
  ffi_lib 'c'

  class FileActions < FFI::Struct
    layout :allocated, :int,
           :user, :int,
           :actions, :pointer,
           :pad, [:int, 16]
  end

  attach_function :_posix_spawn, :posix_spawn, [:pointer, :string, :pointer, :pointer, :pointer, :pointer], :int
  attach_function :_posix_spawnp, :posix_spawnp, [:pointer, :string, :pointer, :pointer, :pointer, :pointer], :int

  attach_function :file_actions_init, :posix_spawn_file_actions_init, [:pointer], :int
  attach_function :file_actions_destroy, :posix_spawn_file_actions_destroy, [:pointer], :int

  attach_function :_file_actions_addopen, :posix_spawn_file_actions_addopen, [:pointer, :int, :pointer, :int, :int], :int
  attach_function :_file_actions_addclose, :posix_spawn_file_actions_addclose, [:pointer, :int], :int
  attach_function :_file_actions_adddup2, :posix_spawn_file_actions_adddup2, [:pointer, :int, :int], :int

  def self.spawn(file, file_actions, *args)
    spawn_args = _prepare_spawn_args(file, file_actions, args)
    _posix_spawn(*spawn_args)
    spawn_args[0].read_int
  end

  def self.spawnp(file, file_actions, *args)
    spawn_args = _prepare_spawn_args(file, file_actions, args)
    _posix_spawnp(*spawn_args)
    spawn_args[0].read_int
  end

  def self.file_actions_add_open(file_actions, fd, path, flags, mode=0644)
    path_byte_count = path.unpack('C*').size
    path_pointer = FFI::MemoryPointer.new(:char, path_byte_count)
    path_pointer.put_bytes(0, path, 0, path_byte_count)
    _file_actions_addopen(file_actions.pointer, fd, path_pointer, flags, mode)
  end

  def self.file_actions_add_close(file_actions, fd)
    _file_actions_addclose(file_actions.pointer, fd)
  end

  def self.file_actions_add_dup(file_actions, source_fd, new_fd)
    _file_actions_adddup2(file_actions.pointer, source_fd, new_fd)
  end

  private
    def self._prepare_spawn_args(file_or_path, file_actions, args)
      pid_ptr = FFI::MemoryPointer.new(:pid_t, 1)

      args_ary = FFI::MemoryPointer.new(:pointer, args.length + 2)
      str_ptrs = args.unshift(file_or_path).map {|str| FFI::MemoryPointer.from_string(str)}
      args_ary.put_array_of_pointer(0, str_ptrs)

      env_ary = FFI::MemoryPointer.new(:pointer, ENV.length + 1)
      env_ptrs = ENV.map {|key,value| FFI::MemoryPointer.from_string("#{key}=#{value}")}
      env_ary.put_array_of_pointer(0, env_ptrs)

      file_actions_pointer = file_actions.nil? ? nil : file_actions.pointer
      [pid_ptr, file_or_path, file_actions_pointer, nil, args_ary, env_ary]
    end
end
