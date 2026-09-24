#!/usr/bin/env python3
"""Own only devices created here. Never accept an arbitrary UDID or edit Photos files."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import uuid

PREFIX = 'PECS-Picker-Harness-Disposable-'
FIXTURES = Path(__file__).resolve().parent.parent / 'Fixtures'


def simctl(*args, capture=False, check=True):
    result = subprocess.run(['xcrun', 'simctl', *args], check=check, text=True,
                            stdout=subprocess.PIPE if capture else sys.stderr)
    return result.stdout.strip() if capture else None


def owned(state):
    record = json.loads(state.read_text())
    if not record['name'].startswith(PREFIX) or record['name'] != PREFIX + record['token']:
        raise SystemExit('Refusing: state does not identify a harness-owned disposable device.')
    devices = json.loads(simctl('list', 'devices', '-j', capture=True))['devices']
    match = [(runtime, device) for runtime, group in devices.items() for device in group
             if device['udid'] == record['udid']]
    if len(match) != 1 or match[0][1]['name'] != record['name'] or match[0][0] != record['runtime']:
        raise SystemExit('Refusing: device identity differs from the recorded disposable simulator.')
    return record, match[0][1]


def create(state, runtime, device_type):
    if state.exists():
        raise SystemExit('State already exists. Use reset or a different --state file.')
    token = str(uuid.uuid4())
    name = PREFIX + token
    udid = simctl('create', name, device_type, runtime, capture=True)
    record = dict(udid=udid, name=name, token=token, runtime=runtime, device_type=device_type)
    # Record ownership immediately, so an interrupted boot can still be cleaned up.
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(json.dumps(record, indent=2) + '\n')
    simctl('boot', udid)
    simctl('bootstatus', udid, '-b')
    simctl('spawn', udid, 'defaults', 'write', 'NSGlobalDomain', 'AppleLanguages', '-array', 'en')
    simctl('spawn', udid, 'defaults', 'write', 'NSGlobalDomain', 'AppleLocale', '-string', 'en_US')
    # Restart services to apply language to the out-of-process picker as well as the host.
    simctl('shutdown', udid)
    simctl('boot', udid)
    simctl('bootstatus', udid, '-b')
    simctl('status_bar', udid, 'override', '--time', '9:41', '--batteryState', 'charged', '--batteryLevel', '100')
    # Stock simulator photos can coexist: tests select the unique EXIF dates below.
    simctl('addmedia', udid, *map(str, sorted(FIXTURES.glob('*.jpg'))))
    print(udid)


def delete(state):
    record, device = owned(state)
    if device['state'] != 'Shutdown':
        simctl('shutdown', record['udid'])
    simctl('delete', record['udid'])
    state.unlink()
    return record


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('command', choices=['create', 'reset', 'delete', 'id'])
parser.add_argument('--state', type=Path, required=True)
parser.add_argument('--runtime', default='com.apple.CoreSimulator.SimRuntime.iOS-26-5')
parser.add_argument('--device-type', default='com.apple.CoreSimulator.SimDeviceType.iPhone-17')
args = parser.parse_args()
if args.command == 'create':
    create(args.state, args.runtime, args.device_type)
elif args.command == 'reset':
    old = delete(args.state)
    create(args.state, old['runtime'], old['device_type'])
elif args.command == 'delete':
    delete(args.state)
else:
    print(owned(args.state)[0]['udid'])
