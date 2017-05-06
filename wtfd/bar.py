import sys

from wtfd.get_running_apps import get_running_apps
from wtfd.monitor_order import monitor_order


class Bar(object):
    def __init__(self):
        self.time = ''
        self.last_update = None
        self.apps_running = None

        # These fields are filled and updated by different reactors and updaters
        self.window_title = ''  # XTitleReactor
        self.monitors = None  # BSPCReactor
        self.volume = None  # VolumeReactor

    def render_desktop(self, monitor, imonitor, desktop, idesktop):
        idesktop_all_screens = idesktop + imonitor * 4
        # The link switches to the clicked desktop
        link = '%{{A:bspc desktop --focus ^{idesktop}:}}{content}%{{A}}'
        icons = self.apps_running[monitor['name']][desktop['name']]
        if len(icons) > 0:
            icons = ' ' + ' '.join(icons) + ' '
        else:
            icons = ''

        content = '  %s %s ' % (desktop['name'], icons)

        background_color = '-'
        line_color = '-'

        if desktop['ocuppied']:
            background_color = '#4F6F4F'  # green

        if desktop['status'] == 'u':  # urgent
            # Use a red bar if the desktop has an urgent window
            line_color = '#FF2020'
            background_color = '#FF6F6F'
        elif desktop['focused']:
            # Use a green bar if the desktop is focused
            line_color = '#00FF00'

        # Wrap content with background
        content = '%{{B{background}}}{0}%{{B-}}'.format(content,
                                                        background=background_color)

        # Wrap content with underline
        if line_color != '-':
            content = '%{{U{line}}}%{{+u}}{0}%{{-u}}'.format(content,
                                                             line=line_color)

        # Wrap content with link
        return link.format(idesktop=idesktop_all_screens,
                           content=content)

    def render_desktops(self, monitor, imonitor):
        return '  '.join(
            self.render_desktop(monitor, imonitor, desktop, idesktop)
            for idesktop, desktop in enumerate(monitor['desktops'], 1)
        )

    def render_layout(self, monitor):
        return '%{F#FFCE88}' + monitor['layout'] + '%{F-}'

    def render_monitor(self, monitor, imonitor):
        out = '%{{l}}{margin}{desktops}' \
              '%{{c}}{title}' \
              '%{{r}}{layout}   {volume}  {time}{margin}'.format(**{
            'margin': ' ' * 4,
            'desktops': self.render_desktops(monitor, imonitor),
            'title': self.window_title,
            'volume': self.render_volume(),
            'time': self.time,
            'layout': self.render_layout(monitor),
        })
        return out

    def render_volume(self):
        if self.volume is None:
            out = ""
        else:
            if self.volume['muted']:
                speaker_icon = '\uf026'
            else:
                speaker_icon = '\uf028'

            number_bars = 16
            volume = min(self.volume['max_volume'], 1)

            if not self.volume['muted']:
                filled_bars = round(number_bars * volume)
            else:
                filled_bars = 0
            empty_bars = number_bars - filled_bars

            filled_bar_icon = '%{F#FFFFFF}\uf402%{F-}'
            empty_bar_icon = '%{F#7F7F7F}\uf402%{F-}'  # '\u25af'

            bars = (filled_bar_icon * filled_bars) + (empty_bar_icon * empty_bars)

            out = "%s %s" % (speaker_icon, bars)
        return out

    def render(self):
        if self.monitors is None:
            return None  # skip for now

        self.apps_running = get_running_apps()

        if len(self.monitors) > 0:
            buf = ''

            for imonitor, monitor in enumerate(self.monitors):
                # ignore removed monitors (those that were connected and
                # therefore bspwm remembers them but they are no longer used)
                if monitor['name'] in monitor_order.keys():
                    buf += '%{{S{0}}}{1}'.format(
                        monitor_order[monitor['name']],
                        self.render_monitor(monitor, imonitor))
            return buf

    def update(self):
        new_update = self.render()
        if new_update is not None and new_update != self.last_update:
            print(new_update)
            sys.stdout.flush()
            self.last_update = new_update
