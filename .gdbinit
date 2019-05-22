set history save on
set history size 2048
set history remove-duplicates 1
set history filename ~/.gdb_history
set disassembly-flavor intel

python
import sys, os
sys.path.append(os.path.expanduser("~/dotfiles"))
import gdbDisplayLockedThreads
end
