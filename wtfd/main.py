import os
import sys

def main():
    from wtfd.io_loop import io_loop
    from wtfd.reactors.bspc_reactor import BspcReactor
    from wtfd.reactors.volume_reactor import VolumeReactor
    from wtfd.reactors.xtitle_reactor import XTitleReactor
    from wtfd.update_time import update_time

    # Be unbuffered
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 1)

    # Instantiate reactors
    XTitleReactor()
    VolumeReactor(audio_sink='analog')
    BspcReactor()
    update_time()

    io_loop.start()