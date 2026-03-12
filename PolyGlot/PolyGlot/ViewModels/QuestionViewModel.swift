import Foundation
import Observation

@Observable
final class QuestionViewModel {
    var questionText: String = ""
    var isLoading: Bool = false
}
