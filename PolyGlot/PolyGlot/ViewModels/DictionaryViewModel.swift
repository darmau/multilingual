import Foundation
import Observation

@Observable
final class DictionaryViewModel {
    var searchText: String = ""
    var isLoading: Bool = false
}
