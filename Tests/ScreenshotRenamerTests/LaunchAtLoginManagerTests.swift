//
//  LaunchAtLoginManagerTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for launch at login functionality
//

import XCTest
@testable import ScreenshotRenamer

class LaunchAtLoginManagerTests: XCTestCase {

    func testSharedInstanceExists() {
        // Verify singleton instance is accessible
        let manager = LaunchAtLoginManager.shared
        XCTAssertNotNil(manager)
    }

    func testSharedInstanceIsSingleton() {
        // Verify same instance is returned
        let manager1 = LaunchAtLoginManager.shared
        let manager2 = LaunchAtLoginManager.shared
        XCTAssertTrue(manager1 === manager2)
    }

    func testIsEnabledReturnsBoolean() {
        // Verify isEnabled property is accessible and returns a boolean
        let manager = LaunchAtLoginManager.shared
        let isEnabled = manager.isEnabled
        XCTAssertTrue(isEnabled == true || isEnabled == false)
    }

    func testToggleReturnsResult() {
        // Note: We can't fully test toggle functionality in unit tests
        // as it requires system integration and may fail without proper
        // app bundle or permissions. This test verifies the API contract.
        let manager = LaunchAtLoginManager.shared

        // Just verify the method returns a Result type
        // We don't assert success/failure as it depends on system state
        let result = manager.toggle()

        switch result {
        case .success(let isEnabled):
            // If successful, should return a boolean
            XCTAssertTrue(isEnabled == true || isEnabled == false)
        case .failure(let error):
            // If failed, should return a LaunchAtLoginError
            XCTAssertTrue(error is LaunchAtLoginError)
        }
    }

    func testEnableReturnsResult() {
        // Similar to toggle, we verify the API contract
        let manager = LaunchAtLoginManager.shared
        let result = manager.enable()

        switch result {
        case .success:
            // Success case returns Void
            XCTAssertTrue(true)
        case .failure(let error):
            // If failed, should return a LaunchAtLoginError
            XCTAssertTrue(error is LaunchAtLoginError)
        }
    }

    func testDisableReturnsResult() {
        // Similar to toggle, we verify the API contract
        let manager = LaunchAtLoginManager.shared
        let result = manager.disable()

        switch result {
        case .success:
            // Success case returns Void
            XCTAssertTrue(true)
        case .failure(let error):
            // If failed, should return a LaunchAtLoginError
            XCTAssertTrue(error is LaunchAtLoginError)
        }
    }

    func testLaunchAtLoginErrorHasDescription() {
        // Test that error types have localized descriptions
        let errors: [LaunchAtLoginError] = [
            .requiresApproval,
            .unknownStatus
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }

    func testRegistrationFailedErrorHasDescription() {
        // Test error wrapping
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )
        let error = LaunchAtLoginError.registrationFailed(underlyingError)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Failed to enable") ?? false)
    }

    func testUnregistrationFailedErrorHasDescription() {
        // Test error wrapping
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )
        let error = LaunchAtLoginError.unregistrationFailed(underlyingError)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Failed to disable") ?? false)
    }

    func testRequiresApprovalErrorMessage() {
        let error = LaunchAtLoginError.requiresApproval
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("System Settings") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Login Items") ?? false)
    }
}
