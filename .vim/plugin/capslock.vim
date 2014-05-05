" Unset Caps Lock when leaving insert mode

python << EOF

import vim
from ctypes import *
try:
    X11 = cdll.LoadLibrary("libX11.so.6")
except OSError:
    X11 = None

no_display = False

def unset_caps_lock():
    global no_display
    if no_display:
        # If XOpenDisplay fails, do not retry.
        # This way we avoid outputting an X11 error to the terminal each time
        # the user presses Esc.
        return

    display = X11.XOpenDisplay(None) if X11 else None
    if display:
        X11.XkbLockModifiers(display, c_uint(0x0100), c_uint(2), c_uint(0))
        X11.XCloseDisplay(display)
    else:
        no_display = True

EOF

autocmd InsertLeave * python unset_caps_lock()
