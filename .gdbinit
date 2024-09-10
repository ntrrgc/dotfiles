set debuginfod enabled on
set pagination off
set history save on
set history size 2048
set history remove-duplicates 1
set history filename ~/.gdb_history
set disassembly-flavor intel

# Hack: Bad and fragile. I really hope there is a better alternative that I just don't know yet.
# Update: The official solution is rust-gdb, which is also kind of a hack.
set substitute-path /rustc/eeb90cda1969383f56a2637cbd3037bdf598841c /home/ntrrgc/Apps/rust/rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust

python
import sys, os

sys.path.append(os.path.expanduser("~/dotfiles"))
import gdbDisplayLockedThreads
import gdbCCasts

try:
    sys.path.append(os.path.expanduser("~/Apps/gstreamer/subprojects/gstreamer/libs/gst/helpers"))
    import gst_gdb
    gst_gdb.register(gdb)
except:
    print("Couldn't load the GStreamer GDB support library.")

sys.path.insert(0, os.path.expanduser("~/Apps/webkit/Tools/gdb"))
import webkit
end
