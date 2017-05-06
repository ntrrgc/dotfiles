import subprocess

monitors = subprocess.check_output(['monitor-order']).decode().strip().split(',')

monitor_order = {
    name: index
    for (index, name) in enumerate(monitors)
}