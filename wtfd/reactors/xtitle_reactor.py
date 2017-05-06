from wtfd.bar_singleton import bar
from wtfd.process_reactor import ProcessReactor


class XTitleReactor(ProcessReactor):
    def __init__(self):
        super().__init__(['xtitle', '-s'])

    def on_line(self, line: str):
        bar.window_title = line
        bar.update()
