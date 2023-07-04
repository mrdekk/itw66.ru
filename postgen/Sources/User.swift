//  Created by Denis Malykh on 03.07.2023.

import Foundation

struct User {
    let id: Int
    let login: String
    let realName: String?
    let email: String?
    let url: String?
}

extension Collection where Element == User {
    func asJekyllAuthors() -> String {
        var lines = [String]()
        for user in self {
            lines.append("\(user.login):")
            lines.append("    name: \(user.realName ?? user.login)")
            if let email = user.email {
                lines.append("    email: \(email)")
            }
            if let url = user.url {
                lines.append("    url: \(url.modifiedURL)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\r\n")
    }
}

private extension String {
    var modifiedURL: String {
        if !hasPrefix("http") {
            return "http://" + self
        }
        return self
    }
}
