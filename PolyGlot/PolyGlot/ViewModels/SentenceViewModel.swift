import Foundation
import Observation

@Observable
final class SentenceViewModel {
    var inputText: String = ""
    var isLoading: Bool = false
}
