"""Validate complete runs, including only explicitly inapplicable product/device cases."""

PLUS_ONLY = {
    'PECS_MakerUITests/testChoiceBoardVoicePicker()',
    'PECS_MakerUITests/testDesignBoardReturnsToEditor()',
    'PhotoSelectionScreenTests/testChoiceBoardFitsThreeByFiveOnPortraitIPhone()',
    'PhotoSelectionScreenTests/testChoiceBoardFitsTwoByFiveOnLandscapeIPhone()',
    'PhotoSelectionScreenTests/testChoiceBoardScrollsVerticallyForDenseLandscapeLayout()',
    'PhotoSelectionScreenTests/testChoiceBoardScrollsHorizontallyForWideLayout()',
    'PhotoSelectionScreenTests/testChoiceBoardFitsFiveColumnsOnIPhone()',
    'PhotoSelectionScreenTests/testChoiceBoardFollowsChosenLayout()',
}
PHONE_ONLY = {
    'BoardPageEditorUITests/testBackToTopicsAfterCancellingPhoto()',
    'BoardPageEditorUITests/testBackToTopicsAfterSavingPhoto()',
    'BoardPageEditorUITests/testTitleStaysInNavigationBarAndCompactSelectUsesMoreMenu()',
}


def expected_skips(suite, device_type):
    if suite != 'Boardlet':
        return set()
    return PLUS_ONLY | (PHONE_ONLY if 'iPad' in device_type else set())


def validate_results(summary, tree, total, allowed_skips):
    def walk(nodes):
        for node in nodes:
            yield node
            yield from walk(node.get('children', []))
    skipped = {node.get('nodeIdentifier') for node in walk(tree.get('testNodes', []))
               if node.get('nodeType') == 'Test Case' and node.get('result') == 'Skipped'}
    return (summary.get('passedTests') == total - len(allowed_skips)
            and summary.get('skippedTests') == len(allowed_skips)
            and skipped == allowed_skips
            and summary.get('failedTests') == 0
            and summary.get('expectedFailures') == 0)
