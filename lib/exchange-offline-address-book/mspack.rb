require 'libmspack'

module LibMsPack
  attach_function :mspack_create_oab_decompressor, [ :pointer ], :pointer
  attach_function :mspack_destroy_oab_decompressor, [ :pointer ], :void

  class OABDecompressor < FFI::Struct
    layout :decompress, callback([:pointer, :string, :string], :int),
           :decompress_incremental, callback([:pointer, :string, :string, :string], :int)
  end

  def LibMsPack.oab_decompress(source, target)
    dec = LibMsPack.mspack_create_oab_decompressor(nil)
    msoab = LibMsPack::OABDecompressor.new(dec)
    msoab[:decompress].call(dec, source, target)
    LibMsPack.mspack_destroy_oab_decompressor(dec)
  end
end
