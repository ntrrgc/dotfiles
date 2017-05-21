import os
import sys

from wtfd.wanikani_updater import start_wanikani_updater


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
    start_wanikani_updater()

    try:
        io_loop.start()
    except KeyboardInterrupt:
        pass
