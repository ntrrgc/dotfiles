# Patched from the original mp4.jq to not fail if the root is not MP4, as I
# want to be able to use this in the middle of a moov, for example.
def mp4_path(p):
  _decode_value(
    _tree_path(.boxes; .type; p)
  );
def mp4_path:
  ( . as $c
  | format_root
  | mp4_path($c)
  );

# moov.trak.tkhd.track_ID
# moof.traf.tfhd.track_ID

# moov.trak.mdia.minf.stbl.ctts).entries[0].sample_offset
# moov.trak.edts.elst).entries[0].media_time
# moof.traf.trun
