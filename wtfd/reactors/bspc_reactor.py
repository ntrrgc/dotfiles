from wtfd.bar_singleton import bar
from wtfd.process_reactor import ProcessReactor


class BspcReactor(ProcessReactor):
    def __init__(self):
        super().__init__(['bspc', 'subscribe'])

    def on_line(self, line):
        line = line[1:]  # remove leading 'W'
        fields = line.split(':')

        monitors = []
        monitor = None

        for field in fields:
            label, value = field[0], field[1:]
            if label in ('M', 'm'):
                if monitor is not None:
                    monitors.append(monitor)

                monitor = {
                    'name': value,
                    'active': label == 'M',
                    'desktops': [],
                    'layout': 'unknown',
                }
            elif label in ('O', 'F', 'U', 'o', 'f', 'u'):
                # o -> ocuppied
                # f -> free
                # u -> urgent
                # UPPERCASE -> focused
                desktop = {
                    'name': value,
                    'ocuppied': (label.lower() != 'f'),
                    'focused': label.isupper(),
                    'status': label.lower()
                }
                monitor['desktops'].append(desktop)
            elif label == 'L':
                monitor['layout'] = value
        monitors.append(monitor)

        bar.monitors = monitors
        bar.update()
