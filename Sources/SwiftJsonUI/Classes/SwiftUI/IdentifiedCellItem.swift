import Foundation

public struct IdentifiedCellItem: Identifiable, Equatable {
    public let id: String
    public let index: Int
    public let data: [String: Any]

    public init(id: String, index: Int, data: [String: Any]) {
        self.id = id
        self.index = index
        self.data = data
    }

    public static func == (lhs: IdentifiedCellItem, rhs: IdentifiedCellItem) -> Bool {
        lhs.id == rhs.id && lhs.index == rhs.index
    }
}
