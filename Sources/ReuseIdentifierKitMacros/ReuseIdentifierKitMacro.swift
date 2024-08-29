import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

private enum ClassDeclationDiagnostic: String, DiagnosticMessage {
    case classOnly
    case invalidType
    
    var message: String {
        switch self {
        case .classOnly:
            return "This macro can only be applied to class declarations."
        case .invalidType:
            return "This macro can only be applied to UITableViewCell, UICollectionViewCell or UICollectionReusableView"
        }
    }
    
    var diagnosticID: MessageID {
        return MessageID(domain: "ReuseIdentifierKit",
                         id: rawValue)
    }
    
    var severity: DiagnosticSeverity {
        return .error
    }
}

public struct ReuseIdentifierMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: ClassDeclationDiagnostic.classOnly
            )
            context.diagnose(diagnostic)
            return []
        }
        
        guard let inheritedTypes = classDecl.inheritanceClause?.inheritedTypes else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: ClassDeclationDiagnostic.invalidType
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let validCases: Set<String> = [
            "UITableViewCell",
            "UICollectionViewCell",
            "UICollectionReusableView"
        ]
        
        let isValidSubClass = inheritedTypes.contains { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                return validCases.contains(identifierType.name.text)
            }
            return false
        }
        
        if !isValidSubClass {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: ClassDeclationDiagnostic.invalidType
            )
            context.diagnose(diagnostic)
            return []
        }
        
        let className = classDecl.name.text
        
        return [
            "static let identifier = \"\(raw: className)\""
        ]
    }
}

@main
struct ReuseIdentifierKitPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ReuseIdentifierMacro.self,
    ]
}
