

import Foundation

final class Item: Identifiable {
    let id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String = "", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
