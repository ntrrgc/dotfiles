set debuginfod enabled on
set pagination off
set history save on
set history size 2048
set history remove-duplicates 1
set history filename ~/.gdb_history
set disassembly-flavor intel

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
