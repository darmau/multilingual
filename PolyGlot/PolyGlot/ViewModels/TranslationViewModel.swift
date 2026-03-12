import Foundation
import Observation

@Observable
final class TranslationViewModel {
    var sourceText: String = ""
    var translatedText: String = ""
    var isLoading: Bool = false
}
