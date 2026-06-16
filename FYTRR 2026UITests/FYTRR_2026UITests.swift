//
//  FYTRR_2026UITests.swift
//  FYTRR 2026UITests
//
//  Created by EDWIN MENDOZA on 4/7/26.
//

import XCTest

final class FYTRR_2026UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAuthProfileHomeMapFlow() throws {
        let app = XCUIApplication()

        app.launchArguments = ["UITEST_AUTH"]
        app.launch()
        XCTAssertTrue(app.buttons["auth_create_account_button"].waitForExistence(timeout: 5))
        app.terminate()

        app.launchArguments = ["UITEST_PROFILE_SETUP"]
        app.launch()

        let nameField = app.textFields["profile_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UITest User")

        let ageField = app.textFields["profile_age_field"]
        ageField.tap()
        ageField.typeText("30")

        let weightField = app.textFields["profile_weight_field"]
        weightField.tap()
        weightField.typeText("180")

        let continueButton = app.buttons["profile_setup_continue_button"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()
        continueButton.tap()

        XCTAssertTrue(app.buttons["profile_setup_finish_button"].waitForExistence(timeout: 5))
        app.terminate()

        app.launchArguments = ["UITEST_HOME"]
        app.launch()

        let mapTab = app.buttons["home_tab_map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5))
        mapTab.tap()

        let openFullMapButton = app.buttons["home_open_full_map_button"]
        XCTAssertTrue(openFullMapButton.waitForExistence(timeout: 5))
        openFullMapButton.tap()

        let fullMapVisible = app.otherElements["home_fullscreen_map_view"].waitForExistence(timeout: 5)
        let fullListVisible = app.otherElements["home_fullscreen_map_list"].waitForExistence(timeout: 5)
        XCTAssertTrue(fullMapVisible || fullListVisible)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
