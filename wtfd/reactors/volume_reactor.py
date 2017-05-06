import json

from wtfd.bar_singleton import bar
from wtfd.process_reactor import ProcessReactor


class VolumeReactor(ProcessReactor):
    def __init__(self, audio_sink):
        super().__init__(['pulse-volume-monitor', '--json',
                          '--desired-sink', audio_sink])

    def on_line(self, line: str):
        bar.volume = json.loads(line)
        bar.update()
