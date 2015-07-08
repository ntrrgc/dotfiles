function! RunIPython()
  python << EOF
from IPython.terminal.embed import InteractiveShellEmbed
import termios
import os
import sys
import functools

fd = sys.stdin.fileno()
old_attrs = termios.tcgetattr(fd)
new_attrs = termios.tcgetattr(fd)

new_attrs[0] |= termios.ICRNL # map CR to LN on input
new_attrs[1] |= termios.ONLCR # map LF to CRLF on output
new_attrs[3] |= functools.reduce(lambda a, b: a | b, [
        termios.ECHO,   # local echo
        termios.ISIG,   # send signal on ^C
        termios.ICANON,  # canonical mode
        termios.ECHOE,  # handle erase key
        termios.IEXTEN,  # handle special characters
], 0)

# Vim hijacks sys.stdout so print will normally write to :messages
vim_stdout = sys.stdout
sys.stdout = os.fdopen(1, 'w', 0)

try:
    termios.tcsetattr(fd, termios.TCSANOW, new_attrs)
    sys.stdout.write('\033[?25h') # Show cursor
    sys.stdout.write('\033[?9l') # Disable mouse event tracking
    #sys.stdout.write('\033[?1007l') # Disable alternate scroll mode,
        # so the scroll wheel scrolls instead of sending key codes (does not work)

    ipshell = InteractiveShellEmbed()
    ipshell()
finally:
    # Restore terminal
    termios.tcsetattr(fd, termios.TCSANOW, old_attrs)
    sys.stdout.write('\033[?25l') # Hide cursor
    #sys.stdout.write('\033[?1007h') # Enable alternate scroll mode (does not work)
    if vim.options['mouse'] != '':
        sys.stdout.write('\033[?1003h') # Enable mouse and highlight tracking

    sys.stdout = vim_stdout
EOF
  redraw!
endfunction

command! RunIPython :call RunIPython()
