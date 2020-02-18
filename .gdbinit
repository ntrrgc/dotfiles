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

sys.path.append(os.path.expanduser("~/Apps/gst-build/subprojects/gstreamer/libs/gst/helpers"))
import gst_gdb
gst_gdb.register(gdb)

sys.path.insert(0, "/webkit/Tools/gdb")
import webkit
end
