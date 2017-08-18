# Map of class name to Font-Awesome icon
from typing import Dict, Tuple, Union

class_map: Dict[str, str] = {}

_class_map = {
    ("chrome",
     "google-chrome",
     "google-chrome-stable",
     "google-chrome-unstable",
     "chromium"):
        "\uf268",

    "firefox": "\uf269",

    ("epiphany", "minibrowser"): "\uf267",

    # yeah, I use all of those
    # Check the classes with xprop |grep WM_CLASS
    ("jetbrains-pychar",
     "jetbrains-pycharm-ce",
     "jetbrains-webstorm",
     "jetbrains-idea",
     "jetbrains-idea-c",
     "jetbrains-idea-ce",
     "jetbrains-clion",
     "jetbrains-studi",
     "jetbrains-phpstorm",
     "jetbrains-studio",  # Android Studio
     "emacs",
     "code",
     "qtcreator"):
        "\uf121",

    "gvim": "\uf27d",
    "teamspeak 3": "\uf0c0",
    "steam": "\uf1b6",
    "": "\uf1bc", # spotify... but also some other misbehaving apps that don't
                  # set class name or set it too late for bspwm to notice
    ("dolphin", "dolphin4"): "\uf07c",
    "thunderbird": "\uf003",
    "skype": "\uf17e",
    ("gajim", "revolt"): "\uf075",
    "clementine": "\uf001",
    ("gnome-terminal",
     "konsole",
     "xterm",
     "termite",
     "terminology",
     "urxvt"):
        "\uf120",
    "okular": "\uf02d",
    ("gimp",
     "krita",
     "mypaint"): "\uf1fc",
    "inkscape": "\uf040",
}

def _expand_to_list(item):
    if isinstance(item, tuple):
        return item
    else:
        return (item, )

for keys, value in _class_map.items():
    for key in _expand_to_list(keys):
        assert key == "" or key.islower()
        class_map[key] = value