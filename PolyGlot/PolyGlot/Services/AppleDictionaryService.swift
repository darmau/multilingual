import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import CoreServices
#endif

/// Provides access to the system dictionary (built-in on iOS/macOS).
/// Returns a plain-text definition when available.
@MainActor
final class AppleDictionaryService {

    /// Result of a system dictionary lookup.
    struct DictionaryResult {
        let term: String
        let definition: String
        /// True when the definition came from the system dictionary;
        /// false when it is a placeholder "no definition found" message.
        let found: Bool
    }

    /// Checks whether the system dictionary has a definition for the given term.
    static func hasDefinition(for term: String) -> Bool {
        #if canImport(UIKit)
        return UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term)
        #else
        // macOS: DCSCopyTextDefinition is a CoreServices C function
        if let definition = DCSCopyTextDefinition(nil, term as CFString, CFRangeMake(0, term.count)) {
            let text = definition.takeRetainedValue() as String
            return !text.isEmpty
        }
        return false
        #endif
    }

    /// Looks up the term in the system dictionary and returns the definition text.
    /// On macOS this returns the actual text; on iOS it returns a flag indicating
    /// availability (the full definition is shown via `UIReferenceLibraryViewController`).
    static func lookup(term: String) -> DictionaryResult {
        #if os(macOS)
        if let definition = DCSCopyTextDefinition(nil, term as CFString, CFRangeMake(0, term.count)) {
            let text = definition.takeRetainedValue() as String
            if !text.isEmpty {
                return DictionaryResult(term: term, definition: text, found: true)
            }
        }
        return DictionaryResult(term: term, definition: String(localized: "Term not found in system dictionary."), found: false)
        #else
        if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term) {
            return DictionaryResult(
                term: term,
                definition: String(localized: "Definition available. Tap the button below to view."),
                found: true
            )
        }
        return DictionaryResult(term: term, definition: String(localized: "Term not found in system dictionary."), found: false)
        #endif
    }
}
