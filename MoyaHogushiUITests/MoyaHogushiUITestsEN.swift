import XCTest

/// 英語ロケールを強制して、主要画面の文言が翻訳されていることを確認するスモークテスト。
/// 日本語版(MoyaHogushiUITests)と同じ流れを英語文字列で辿る。
final class MoyaHogushiUITestsEN: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        return app
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @discardableResult
    private func waitFor(_ element: XCUIElement, _ timeout: TimeInterval = 8) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    @discardableResult
    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isEnabled { return true }
            usleep(100_000)
        }
        return element.exists && element.isEnabled
    }

    private func settle(_ seconds: TimeInterval = 0.5) {
        Thread.sleep(forTimeInterval: seconds)
    }

    func testEmptyHomeInEnglish() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(waitFor(app.buttons["Start writing"]), "\"Start writing\" button not shown in English")
        XCTAssertFalse(app.staticTexts["Weekly Review"].exists, "Weekly Review shown with zero entries")
        settle()
        snap("en_01_home_empty")
    }

    func testWriteToReleaseInEnglish() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(waitFor(app.buttons["Start writing"]))
        app.buttons["Start writing"].tap()

        XCTAssertTrue(waitFor(app.staticTexts["1 of 4 · Write"]), "Step 1 header not translated")
        let editor = app.textViews.element
        XCTAssertTrue(waitFor(editor))
        editor.tap()
        editor.typeText("My coworker and I don't see eye to eye on how to run this project.")
        let next1 = app.buttons["Next"]
        XCTAssertTrue(waitUntilEnabled(next1), "\"Next\" not translated or not enabled")
        settle()
        snap("en_02_step1_write")
        next1.tap()

        XCTAssertTrue(waitFor(app.staticTexts["2 of 4 · Feel"]), "Step 2 header not translated")
        app.buttons["Irritated"].tap()
        settle()
        snap("en_03_step2_feel")
        app.buttons["Next"].tap()

        XCTAssertTrue(waitFor(app.staticTexts["3 of 4 · Think"]), "Step 3 header not translated")
        let changeable = app.buttons.element(matching: NSPredicate(format: "label BEGINSWITH %@", "I can change it"))
        changeable.tap()
        let next3 = app.buttons["Next"]
        XCTAssertTrue(waitUntilEnabled(next3))
        settle()
        snap("en_04_step3_think")
        next3.tap()

        XCTAssertTrue(waitFor(app.staticTexts["4 of 4 · Release"]), "Step 4 header not translated")
        let actionField = app.textFields["e.g. Send a message to check in first thing tomorrow"]
        XCTAssertTrue(waitFor(actionField), "Action field placeholder not translated")
        actionField.tap()
        actionField.typeText("Send a message tomorrow morning to align on the plan")
        settle()
        snap("en_05_step4_release")
        app.buttons["Release"].tap()

        XCTAssertTrue(
            waitFor(app.staticTexts["Your step is set. All that's left is to do it. We'll hold onto the rest for you."], 6),
            "Completion screen not translated"
        )
        settle()
        snap("en_06_release_complete")
        app.buttons["Back to Home"].tap()

        XCTAssertTrue(waitFor(app.staticTexts["Weekly Review"]), "Weekly Review not shown after an entry, or not translated")
        XCTAssertTrue(app.staticTexts["Recent Entries"].exists, "Recent Entries not translated")
        XCTAssertTrue(app.staticTexts["Next Steps"].exists, "Next Steps not translated")
        settle()
        snap("en_07_home_with_entry")

        app.buttons["Entries"].tap()
        XCTAssertTrue(waitFor(app.staticTexts["1 total"]), "Journal entry count not translated")
        settle()
        snap("en_08_journal")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(waitFor(app.buttons["Settings"]))
        app.buttons["Settings"].tap()
        XCTAssertTrue(waitFor(app.staticTexts["Upgrade to Pro"]), "Settings Pro upsell not translated")
        XCTAssertTrue(app.staticTexts["Sync with iCloud"].exists, "iCloud sync toggle not translated")
        settle()
        snap("en_09_settings")
    }
}
