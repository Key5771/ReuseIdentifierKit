import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ReuseIdentifierKitMacros)
import ReuseIdentifierKitMacros

let testMacros: [String: Macro.Type] = [
    "ReuseIdentifier": ReuseIdentifierMacro.self,
]
#endif

final class ReuseIdentifierKitTests: XCTestCase {
    func testMacro() throws {
        #if canImport(ReuseIdentifierKitMacros)
        assertMacroExpansion(
            """
            @ReuseIdentifier
            class MyCell: UITableViewCell {
                
            }
            """,
            expandedSource: """
            class MyCell: UITableViewCell {
            
                static let identifier = "MyCell"
                
            }
            """,
            macros: testMacros
        )
        #endif
    }
    
    func testDiagnotics() throws {
        assertMacroExpansion(
            """
            @ReuseIdentifier
            struct MyCell {
            }
            """,
            expandedSource: """
            
            struct MyCell {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "This macro can only be applied to class declarations.", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testNotCellOrReusableType() throws {
        assertMacroExpansion(
            """
            @ReuseIdentifier
            class MyCell {
            }
            """,
            expandedSource: """
            
            class MyCell {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "This macro can only be applied to UITableViewCell, UICollectionViewCell or UICollectionReusableView", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}
