#!/usr/bin/env python3
"""Run every Boardlet test and the shared picker tests on owned disposable devices."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SIMULATOR = ROOT / 'PhotoPickerHarness/Scripts/simulator.py'
MATRIX = [('18-4-phone-portrait', '18.4', 'iPhone-16', 'Portrait'),
          ('26-phone-portrait', '26.', 'iPhone-17', 'Portrait'),
          ('27-phone-portrait', '27.0', 'iPhone-17', 'Portrait'),
          ('18-4-pad-portrait', '18.4', 'iPad-A16', 'Portrait'),
          ('18-4-pad-landscape', '18.4', 'iPad-A16', 'Landscape'),
          ('27-pad-portrait', '27.0', 'iPad-Pro-11-inch-M4-8GB', 'Portrait'),
          ('27-pad-landscape', '27.0', 'iPad-Pro-11-inch-M4-8GB', 'Landscape')]


def run(command, log, env=None):
    with log.open('w') as output:
        return subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, env=env).returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--configuration', choices=[x[0] for x in MATRIX], action='append')
    parser.add_argument('--keep-sim', action='store_true')
    parser.add_argument('--derived-data', type=Path)
    parser.add_argument('--packages', type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    runtimes = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'runtimes', '-j']))
    (args.output / 'runtimes.json').write_text(json.dumps(runtimes, indent=2))
    run(['xcodebuild', '-version'], args.output / 'xcode-version.txt')
    run(['sw_vers'], args.output / 'host-version.txt')
    boardlet_derived = args.derived_data or args.output / 'BoardletDerived'
    package_args = (['-clonedSourcePackagesDirPath', str(args.packages),
                     'BOARDLET_PACKAGE_CHECKOUTS=' + str(args.packages / 'checkouts')] if args.packages else [])
    rows = []
    for name, family, model, orientation in MATRIX:
        if args.configuration and name not in args.configuration:
            continue
        folder = args.output / name
        folder.mkdir()  # Refuse to overwrite earlier evidence or ownership records.
        record = dict(configuration=name, orientation=orientation, result='NOT RUN')
        rows.append(record)
        available = [r for r in runtimes['runtimes'] if r.get('isAvailable')
                     and r['version'].startswith(family)
                     and tuple(map(int, r['version'].split('.'))) >= (16, 6)]
        if not available:
            record.update(result='BLOCKED', reason='No available runtime in this OS family at or above the existing iOS 16.6 deployment target.')
            (folder / 'result.json').write_text(json.dumps(record, indent=2))
            continue
        runtime = max(available, key=lambda r: tuple(map(int, r['version'].split('.'))))
        device_type = 'com.apple.CoreSimulator.SimDeviceType.' + model
        record.update(runtime=runtime, device_type=device_type)
        state = folder / 'simulator.json'
        try:
            code = run(['python3', str(SIMULATOR), 'create', '--state', str(state),
                        '--runtime', runtime['identifier'], '--device-type', device_type], folder / 'setup.log')
            if code:
                raise RuntimeError(f'Simulator setup failed with exit {code}')
            ownership = json.loads(state.read_text())
            record['simulator'] = ownership
            (folder / 'simulator-record.json').write_text(json.dumps(ownership, indent=2))
            udid = ownership['udid']
            fixtures = folder / 'fixtures'
            code = run(['swift', 'Scripts/SystemPhotoPicker/seed-board-fixtures.swift',
                        'PECS MakerTests/Assets/FruitImages', str(fixtures)], folder / 'fixtures.log')
            if code:
                raise RuntimeError(f'Fixture generation failed with exit {code}')
            subprocess.run(['xcrun', 'simctl', 'addmedia', udid, *map(str, sorted(fixtures.glob('*.jpg')))], check=True)
            common = ['-destination', f'platform=iOS Simulator,id={udid}', '-parallel-testing-enabled', 'NO',
                      '-test-timeouts-enabled', 'YES', '-default-test-execution-time-allowance', '1800',
                      '-maximum-test-execution-time-allowance', '1800',
                      'CODE_SIGNING_ALLOWED=NO', 'ARCHS=arm64']
            # Apply orientation before the full run, including its unit-test host.
            record['orientationExit'] = run(['xcodebuild', '-project', 'PECS Maker.xcodeproj',
                '-scheme', 'Boardlet System Picker', '-testPlan', 'SystemPhotoPickerMatrix',
                '-only-test-configuration', orientation, '-derivedDataPath', str(boardlet_derived),
                '-only-testing:PECS MakerUITests/SystemPickerIntegrationTests/testMatrixOrientation',
                '-resultBundlePath', str(folder / 'Orientation.xcresult'), *package_args, *common, 'test'], folder / 'orientation.log')
            if record['orientationExit']:
                raise RuntimeError('Requested orientation could not be applied and verified')
            record['boardletExit'] = run(['xcodebuild', '-project', 'PECS Maker.xcodeproj',
                '-scheme', 'Boardlet System Picker', '-testPlan', 'SystemPhotoPickerMatrix',
                '-only-test-configuration', orientation, '-derivedDataPath', str(boardlet_derived),
                '-resultBundlePath', str(folder / 'Boardlet.xcresult'), *package_args, *common, 'test'], folder / 'boardlet.log')
            ui_class = 'RealPickerTests' if orientation == 'Portrait' else 'LandscapePickerTests'
            record['harnessExit'] = run(['xcodebuild', '-project', 'PhotoPickerHarness/PhotoPickerHarness.xcodeproj',
                '-scheme', 'PhotoPickerHarness', '-derivedDataPath', str(args.output / 'HarnessDerived'),
                '-only-testing:PhotoPickerHarnessTests', f'-only-testing:PhotoPickerHarnessUITests/{ui_class}',
                '-resultBundlePath', str(folder / 'Harness.xcresult'), *common, 'test'], folder / 'harness.log')
            suites_passed = record['boardletExit'] == record['harnessExit'] == 0
            for suite in ['Boardlet', 'Harness']:
                summary_exit = run(['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(folder / f'{suite}.xcresult')],
                    folder / f'{suite}-summary.json')
                if summary_exit:
                    suites_passed = False
                    continue
                summary = json.loads((folder / f'{suite}-summary.json').read_text())
                suites_passed = suites_passed and summary.get('passedTests') == {'Boardlet': 62, 'Harness': 10}[suite] and all(
                    summary.get(key) == 0 for key in ['failedTests', 'skippedTests', 'expectedFailures'])
            record['result'] = 'PASSED' if suites_passed else 'FAILED'
        except Exception as error:
            record.update(result='FAILED', reason=str(error))
        finally:
            if state.exists() and not args.keep_sim:
                record['cleanupExit'] = run(['python3', str(SIMULATOR), 'delete', '--state', str(state)], folder / 'cleanup.log')
            (folder / 'result.json').write_text(json.dumps(record, indent=2))
            (args.output / 'results.json').write_text(json.dumps(rows, indent=2))
    (args.output / 'results.json').write_text(json.dumps(rows, indent=2))
    return 0 if all(row['result'] == 'PASSED' for row in rows) else 1


if __name__ == '__main__':
    sys.exit(main())
