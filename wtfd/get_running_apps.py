import json
import subprocess

from wtfd.wm_class_icons import class_map


def get_running_apps():
    wm_state = subprocess.check_output(['bspc', 'wm', '--dump-state']).decode()
    wm_state = json.loads(wm_state)

    def process_monitor(monitor):
        return {
            desktop["name"]: process_desktop(desktop)
            for desktop in monitor["desktops"]
        }

    def process_desktop(desktop):
        return process_node(desktop['root'])

    def process_node(node):
        if node is None:
            return []
        else:
            if node['client']:
                this_node_values = process_class(node['client']['className'])
            else:
                this_node_values = []
            return this_node_values + \
                    process_node(node['firstChild']) + \
                    process_node(node['secondChild'])

    def process_class(class_name):
        icon = class_map.get(class_name.lower())
        if icon:
            return [icon]
        else:
            return []

    return {
        monitor['name']: process_monitor(monitor)
        for monitor in wm_state['monitors']
    }
