//
//  TestReporter.swift
//  CoinFlipUITests
//
//  Comprehensive bug reporting utility for UI tests
//

import XCTest

/// Bug report structure with comprehensive details
struct BugReport {
    let testName: String
    let timestamp: Date
    let severity: Severity
    let category: Category
    let description: String
    let expectedBehavior: String
    let actualBehavior: String
    let stepsToReproduce: [String]
    let deviceInfo: DeviceInfo
    let screenshot: XCUIScreenshot?
    let additionalContext: [String: String]

    enum Severity: String {
        case critical = "🔴 CRITICAL"
        case high = "🟠 HIGH"
        case medium = "🟡 MEDIUM"
        case low = "🟢 LOW"
    }

    enum Category: String {
        case functionality = "Functionality"
        case ui = "UI/UX"
        case performance = "Performance"
        case dataConsistency = "Data Consistency"
        case crash = "Crash"
        case authentication = "Authentication"
        case network = "Network"
    }

    struct DeviceInfo {
        let device: String
        let osVersion: String
        let appVersion: String

        static var current: DeviceInfo {
            DeviceInfo(
                device: UIDevice.current.model,
                osVersion: UIDevice.current.systemVersion,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            )
        }
    }

    /// Format bug report as comprehensive markdown
    var formattedReport: String {
        var report = """
        # \(severity.rawValue) Bug Report

        ## Summary
        **Test:** `\(testName)`
        **Timestamp:** \(timestamp.formatted())
        **Category:** \(category.rawValue)
        **Severity:** \(severity.rawValue)

        ## Description
        \(description)

        ## Expected Behavior
        \(expectedBehavior)

        ## Actual Behavior
        \(actualBehavior)

        ## Steps to Reproduce
        """

        for (index, step) in stepsToReproduce.enumerated() {
            report += "\n\(index + 1). \(step)"
        }

        report += """


        ## Device Information
        - **Device:** \(deviceInfo.device)
        - **OS Version:** \(deviceInfo.osVersion)
        - **App Version:** \(deviceInfo.appVersion)

        """

        if !additionalContext.isEmpty {
            report += """
            ## Additional Context
            """
            for (key, value) in additionalContext {
                report += "\n- **\(key):** \(value)"
            }
            report += "\n"
        }

        if screenshot != nil {
            report += "\n## Screenshot\nScreenshot attached to test results.\n"
        }

        report += "\n---\n"

        return report
    }
}

/// Test reporter for collecting and outputting bug reports
class TestReporter {

    static let shared = TestReporter()

    private var bugReports: [BugReport] = []
    private var testMetrics: [String: TestMetrics] = [:]

    private init() {}

    struct TestMetrics {
        let testName: String
        var startTime: Date?
        var endTime: Date?
        var duration: TimeInterval {
            guard let start = startTime, let end = endTime else { return 0 }
            return end.timeIntervalSince(start)
        }
        var passed: Bool = true
        var assertionCount: Int = 0
    }

    /// Start tracking a test
    func startTest(_ testName: String) {
        testMetrics[testName] = TestMetrics(testName: testName, startTime: Date())
        print("\n🧪 Starting test: \(testName)")
    }

    /// End tracking a test
    func endTest(_ testName: String, passed: Bool) {
        if var metrics = testMetrics[testName] {
            metrics.endTime = Date()
            metrics.passed = passed
            testMetrics[testName] = metrics

            let status = passed ? "✅ PASSED" : "❌ FAILED"
            print("🏁 \(status): \(testName) (Duration: \(String(format: "%.2f", metrics.duration))s)")
        }
    }

    /// Record an assertion
    func recordAssertion(testName: String) {
        if var metrics = testMetrics[testName] {
            metrics.assertionCount += 1
            testMetrics[testName] = metrics
        }
    }

    /// Report a bug with comprehensive details
    func reportBug(
        testName: String,
        severity: BugReport.Severity,
        category: BugReport.Category,
        description: String,
        expectedBehavior: String,
        actualBehavior: String,
        stepsToReproduce: [String],
        screenshot: XCUIScreenshot? = nil,
        additionalContext: [String: String] = [:]
    ) {
        let report = BugReport(
            testName: testName,
            timestamp: Date(),
            severity: severity,
            category: category,
            description: description,
            expectedBehavior: expectedBehavior,
            actualBehavior: actualBehavior,
            stepsToReproduce: stepsToReproduce,
            deviceInfo: .current,
            screenshot: screenshot,
            additionalContext: additionalContext
        )

        bugReports.append(report)

        // Print to console immediately
        print("\n" + report.formattedReport)

        // Mark test as failed
        if var metrics = testMetrics[testName] {
            metrics.passed = false
            testMetrics[testName] = metrics
        }
    }

    /// Generate comprehensive test summary report
    func generateSummaryReport() -> String {
        let totalTests = testMetrics.count
        let passedTests = testMetrics.values.filter { $0.passed }.count
        let failedTests = totalTests - passedTests
        let totalBugs = bugReports.count

        var report = """

        ═══════════════════════════════════════════════════════════════
        📊 COMPREHENSIVE UI TEST SUITE SUMMARY REPORT
        ═══════════════════════════════════════════════════════════════

        ## Test Execution Summary
        - **Total Tests:** \(totalTests)
        - **Passed:** ✅ \(passedTests)
        - **Failed:** ❌ \(failedTests)
        - **Pass Rate:** \(totalTests > 0 ? String(format: "%.1f%%", Double(passedTests) / Double(totalTests) * 100) : "N/A")

        ## Bug Summary
        - **Total Bugs Found:** \(totalBugs)
        """

        // Count by severity
        let criticalBugs = bugReports.filter { $0.severity == .critical }.count
        let highBugs = bugReports.filter { $0.severity == .high }.count
        let mediumBugs = bugReports.filter { $0.severity == .medium }.count
        let lowBugs = bugReports.filter { $0.severity == .low }.count

        report += """

        - 🔴 Critical: \(criticalBugs)
        - 🟠 High: \(highBugs)
        - 🟡 Medium: \(mediumBugs)
        - 🟢 Low: \(lowBugs)

        ## Test Details
        """

        for (_, metrics) in testMetrics.sorted(by: { $0.key < $1.key }) {
            let status = metrics.passed ? "✅" : "❌"
            report += "\n\(status) \(metrics.testName) - \(String(format: "%.2f", metrics.duration))s"
        }

        if totalBugs > 0 {
            report += """


            ═══════════════════════════════════════════════════════════════
            🐛 DETAILED BUG REPORTS
            ═══════════════════════════════════════════════════════════════

            """

            for bugReport in bugReports.sorted(by: { $0.severity.rawValue < $1.severity.rawValue }) {
                report += bugReport.formattedReport + "\n"
            }
        } else {
            report += """


            🎉 NO BUGS FOUND! All tests passed successfully.
            """
        }

        report += """


        ═══════════════════════════════════════════════════════════════
        End of Test Report
        ═══════════════════════════════════════════════════════════════

        """

        return report
    }

    /// Clear all reports and metrics (useful between test runs)
    func reset() {
        bugReports.removeAll()
        testMetrics.removeAll()
    }

    /// Get all bug reports
    var allBugReports: [BugReport] {
        return bugReports
    }
}
