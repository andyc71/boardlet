#!/usr/bin/env python3
"""Run complete production suites using the documented disposable Photos fixture ownership tools."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SIMULATOR = ROOT / 'PhotoPickerHarness/Scripts/simulator.py'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--keep-sim', action='store_true')
    parser.add_argument('--variant', choices=['both', 'standard', 'plus'], default='both')
    parser.add_argument('--only-testing', action='append', default=[],
                        help='Class or Class/method to run in the selected UI test target; repeatable')
    parser.add_argument('--skip-testing', action='append', default=[],
                        help='Previously completed UI Class or Class/method to omit from a continuation; repeatable')
    parser.add_argument('--test-timeout', type=int, default=600)
    parser.add_argument('--include-unit-tests', action='store_true',
                        help='Include the complete Standard unit target alongside selected UI tests')
    parser.add_argument('--runtime-version', default='27.0')
    parser.add_argument('--device-type', default='com.apple.CoreSimulator.SimDeviceType.iPhone-17')
    parser.add_argument('--orientation', choices=['Portrait', 'Landscape'])
    parser.add_argument('--without-building', action='store_true',
                        help='Reuse an existing build for the selected scheme and test plan')
    parser.add_argument('--test-run', type=Path,
                        help='Standard .xctestrun to reuse without resolving or building packages')
    args = parser.parse_args()
    if args.orientation and args.variant != 'standard':
        parser.error('--orientation currently requires --variant standard')
    if args.test_run:
        if args.variant != 'standard' or not args.without_building:
            parser.error('--test-run requires --variant standard --without-building')
        if not args.test_run.is_file():
            parser.error('--test-run must identify an existing .xctestrun file')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    commands = []
    results = {}
    def run(command, name):
        commands.append(command)
        (output / 'commands.json').write_text(json.dumps(commands, indent=2))
        with (output / (name + '.log')).open('w') as log:
            code = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT).returncode
        results[name] = code
        (output / 'results.json').write_text(json.dumps(results, indent=2))
        return code
    state = output / 'simulator.json'
    try:
        runtimes = json.loads(subprocess.check_output(['xcrun','simctl','list','runtimes','-j']))['runtimes']
        runtime = next(r for r in runtimes if r.get('isAvailable') and r['version'] == args.runtime_version)
        if run(['python3',str(SIMULATOR),'create','--state',str(state),'--runtime',runtime['identifier'],
                '--device-type',args.device_type],'create'):
            raise RuntimeError('Owned simulator setup failed')
        ownership = json.loads(state.read_text())
        (output / 'simulator-record.json').write_text(json.dumps(ownership,indent=2))
        udid = ownership['udid']
        fixtures = output / 'fixtures'
        if run(['swift','documentation/Scripts/SystemPhotoPicker/seed-board-fixtures.swift',
                'PECS MakerTests/Assets/FruitImages',str(fixtures)],'fixtures'):
            raise RuntimeError('Fixture generation failed')
        if run(['xcrun','simctl','addmedia',udid,*map(str,sorted(fixtures.glob('*.jpg')))],'seed'):
            raise RuntimeError('Fixture seeding failed')
        for name, scheme, plan in [('standard','PECS Maker','BoardLibraryVerification'),('plus','Easy PECS Plus','Easy PECS Plus')]:
            if args.variant != 'both' and name != args.variant:
                continue
            if args.orientation:
                scheme, plan = 'PECS Maker', 'ClassicVerification'
            command = ['xcodebuild']
            if args.test_run:
                command.extend(['-xctestrun', str(args.test_run.resolve())])
            else:
                command.extend(['-project','PECS Maker.xcodeproj','-scheme',scheme,'-testPlan',plan,
                       '-configuration','Debug','-derivedDataPath','.build','-skipMacroValidation',
                       '-disableAutomaticPackageResolution',
                       'BOARDLET_PACKAGE_CHECKOUTS='+str(ROOT/'.build/SourcePackages/checkouts')])
            command.extend(['-destination',f'platform=iOS Simulator,id={udid}',
                       '-parallel-testing-enabled','NO','-collect-test-diagnostics','never',
                       '-test-timeouts-enabled','YES','-default-test-execution-time-allowance',str(args.test_timeout),
                       '-maximum-test-execution-time-allowance',str(args.test_timeout),
                       '-resultBundlePath',str(output/(name+'.xcresult')),
                       'test-without-building' if args.without_building else 'test'])
            if args.orientation:
                command.extend(['-only-test-configuration', args.orientation,
                                '-enableThreadSanitizer', 'NO'])
            target = 'PECS MakerUITests' if name == 'standard' else 'Easy PECS Plus UI Tests'
            command.extend('-only-testing:'+target+'/'+selection for selection in args.only_testing)
            command.extend('-skip-testing:'+target+'/'+selection for selection in args.skip_testing)
            if args.include_unit_tests and name == 'standard' and args.only_testing:
                command.append('-only-testing:PECS MakerTests')
            run(command,name)
            run(['xcrun','xcresulttool','get','test-results','summary','--path',str(output/(name+'.xcresult'))],name+'-summary')
            run(['xcrun','xcresulttool','get','test-results','tests','--path',str(output/(name+'.xcresult'))],name+'-tests')
    finally:
        if state.exists() and not args.keep_sim:
            run(['python3',str(SIMULATOR),'delete','--state',str(state)],'cleanup')
    return 0 if all(code == 0 for code in results.values()) else 1

if __name__ == '__main__':
    sys.exit(main())
