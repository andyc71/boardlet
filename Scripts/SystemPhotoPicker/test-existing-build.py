#!/usr/bin/env python3
"""Run the complete matrix row from reusable test builds on a harness-owned device."""
import argparse
import json
import plistlib
from pathlib import Path
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state', required=True, type=Path)
    parser.add_argument('--orientation', required=True, choices=['Portrait', 'Landscape'])
    parser.add_argument('--boardlet-test-run', required=True, type=Path)
    parser.add_argument('--harness-test-run', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    state = json.loads(args.state.read_text())
    token = str(uuid.UUID(state['token']))
    if state['name'] != 'PECS-Picker-Harness-Disposable-' + token:
        raise SystemExit('Refusing a simulator without a valid harness ownership record')
    devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', '-j']))['devices']
    matches = [d for d in devices.get(state['runtime'], []) if d['udid'] == state['udid']
               and d['name'] == state['name'] and d.get('deviceTypeIdentifier') == state['device_type']]
    if len(matches) != 1:
        raise SystemExit('Ownership record does not match the installed simulator')
    for path in [args.boardlet_test_run, args.harness_test_run]:
        if not path.is_file():
            raise SystemExit(f'Missing reusable test build: {path}')
    test_run = plistlib.loads(args.boardlet_test_run.read_bytes())
    configurations = [c for c in test_run.get('TestConfigurations', []) if c.get('Name') == args.orientation]
    if len(configurations) != 1:
        raise SystemExit('Reusable build must contain the requested test configuration')
    targets = configurations[0].get('TestTargets', [])
    if {t.get('BlueprintName') for t in targets} != {'PECS MakerTests', 'PECS MakerUITests'}:
        raise SystemExit('Reusable build must contain both complete Boardlet test targets')
    if any(t.get('OnlyTestIdentifiers') or t.get('SkipTestIdentifiers') for t in targets):
        raise SystemExit('Refusing a filtered Boardlet test build')
    args.output.mkdir(parents=True, exist_ok=False)
    record = dict(simulator=state, orientation=args.orientation, result='RUNNING', steps={})
    commands = []

    def save():
        (args.output / 'result.json').write_text(json.dumps(record, indent=2))
        (args.output / 'commands.json').write_text(json.dumps(commands, indent=2))

    def run(command, name):
        commands.append(command)
        save()
        with (args.output / (name + '.log')).open('w') as output:
            result = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT)
        return result.returncode

    try:
        if matches[0]['state'] == 'Booted':
            if run(['xcrun', 'simctl', 'shutdown', state['udid']], 'shutdown'):
                raise RuntimeError('Unable to shut down owned simulator')
        if run(['xcrun', 'simctl', 'boot', state['udid']], 'boot'):
            raise RuntimeError('Unable to boot owned simulator')
        if run(['xcrun', 'simctl', 'bootstatus', state['udid'], '-b'], 'boot-status'):
            raise RuntimeError('Owned simulator did not finish booting')
        run(['xcodebuild', '-version'], 'xcode-version')
        run(['sw_vers'], 'host-version')
        common = ['-destination', f"platform=iOS Simulator,id={state['udid']}",
                  '-parallel-testing-enabled', 'NO', '-test-timeouts-enabled', 'YES',
                  '-default-test-execution-time-allowance', '1800',
                  '-maximum-test-execution-time-allowance', '1800']
        boardlet = ['-xctestrun', str(args.boardlet_test_run), '-only-test-configuration', args.orientation]
        ui_class = 'RealPickerTests' if args.orientation == 'Portrait' else 'LandscapePickerTests'
        steps = [('Orientation', boardlet + ['-only-testing:PECS MakerUITests/SystemPickerIntegrationTests/testMatrixOrientation']),
                 ('Boardlet', boardlet),
                 ('Harness', ['-xctestrun', str(args.harness_test_run), '-only-testing:PhotoPickerHarnessTests',
                              '-only-testing:PhotoPickerHarnessUITests/' + ui_class])]
        for name, options in steps:
            bundle = args.output / (name + '.xcresult')
            code = run(['xcodebuild', *options, *common, '-resultBundlePath', str(bundle), 'test-without-building'], name)
            result = dict(exitCode=code)
            record['steps'][name] = result
            summary_code = run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(bundle)], name + '-summary')
            if summary_code == 0:
                summary = json.loads((args.output / (name + '-summary.log')).read_text())
                result.update({key: summary.get(key) for key in ['passedTests', 'failedTests', 'skippedTests', 'expectedFailures']})
            expected_tests = {'Orientation': 1, 'Boardlet': 62, 'Harness': 10}[name]
            result['expectedTests'] = expected_tests
            result['passed'] = code == 0 and summary_code == 0 and result.get('passedTests') == expected_tests and all(
                result.get(key) == 0 for key in ['failedTests', 'skippedTests', 'expectedFailures'])
            save()
            if name == 'Orientation' and not result['passed']:
                raise RuntimeError('Requested orientation was not verified')
        record['result'] = 'PASSED' if all(s['passed'] for s in record['steps'].values()) else 'FAILED'
    except Exception as error:
        record.update(result='FAILED', reason=str(error))
    finally:
        save()
    return 0 if record['result'] == 'PASSED' else 1


if __name__ == '__main__':
    raise SystemExit(main())
