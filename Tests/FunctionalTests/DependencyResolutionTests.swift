/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest

import TSCBasic
import Commands
import SPMTestSupport
import SourceControl
import Workspace

class DependencyResolutionTests: XCTestCase {
    func testInternalSimple() {
        fixture(name: "DependencyResolution/Internal/Simple") { prefix in
            XCTAssertBuilds(prefix)

            let output = try Process.checkNonZeroExit(args: prefix.appending(components: ".build", Resources.default.toolchain.triple.tripleString, "debug", "Foo").pathString)
            XCTAssertEqual(output, "Foo\nBar\n")
        }
    }

    func testInternalExecAsDep() {
        fixture(name: "DependencyResolution/Internal/InternalExecutableAsDependency") { prefix in
            XCTAssertBuildFails(prefix)
        }
    }

    func testInternalComplex() {
        fixture(name: "DependencyResolution/Internal/Complex") { prefix in
            XCTAssertBuilds(prefix)

            let output = try Process.checkNonZeroExit(args: prefix.appending(components: ".build", Resources.default.toolchain.triple.tripleString, "debug", "Foo").pathString)
            XCTAssertEqual(output, "meiow Baz\n")
        }
    }

    /// Check resolution of a trivial package with one dependency.
    func testExternalSimple() {
        fixture(name: "DependencyResolution/External/Simple") { prefix in
            // Add several other tags to check version selection.
            let repo = GitRepository(path: prefix.appending(components: "Foo"))
            for tag in ["1.1.0", "1.2.0"] {
                try repo.tag(name: tag)
            }

            let packageRoot = prefix.appending(component: "Bar")
            XCTAssertBuilds(packageRoot)
            XCTAssertFileExists(prefix.appending(components: "Bar", ".build", Resources.default.toolchain.triple.tripleString, "debug", "Bar"))
            let path = try SwiftPMProduct.packagePath(for: "Foo", packageRoot: packageRoot)
            XCTAssert(try GitRepository(path: path).getTags().contains("1.2.3"))
        }
    }

    func testExternalComplex() {
        fixture(name: "DependencyResolution/External/Complex") { prefix in
            XCTAssertBuilds(prefix.appending(component: "app"))
            let output = try Process.checkNonZeroExit(args: prefix.appending(components: "app", ".build", Resources.default.toolchain.triple.tripleString, "debug", "Dealer").pathString)
            XCTAssertEqual(output, "♣︎K\n♣︎Q\n♣︎J\n♣︎10\n♣︎9\n♣︎8\n♣︎7\n♣︎6\n♣︎5\n♣︎4\n")
        }
    }
}
