//  Created by Denis Malykh on 22.06.2023.

import Foundation

struct Post {
    let id: String
    let blogId: Int
    let title: String
    let dateAdd: Date
    let user: String
    let tags: [String]
    let text: String
    let comments: [Comment]
    
    func jekyllFileName() -> String {
        "\(dateFormatter.string(from: dateAdd))-\(title.russianTransliterated).md"
    }
    
    func asJekyll(blog: Blog) -> String {
        
        let regex = try! NSRegularExpression(pattern: "<cut.*>")
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        var content = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "\r\n<!--cut-->\r\n")
        
        let imgRegex = try! NSRegularExpression(pattern: "<img.*src=\\\"([\\w\\/:\\.]*)\\\".*alt=\\\"([^\\\"]*)\\\".*\\/>")
        content = imgRegex.stringByReplacingMatches(
            in: content,
            range: NSRange(content.startIndex..<content.endIndex, in: content),
            withTemplate: "\r\n![$2]($1)\r\n"
        )
        
        let aRegex = try! NSRegularExpression(pattern: "<a.*href=\\\"([#()+&\\?=%\\w\\/:\\.-]*)\\\".*>(.*)<\\/a>")
        content = aRegex.stringByReplacingMatches(
            in: content,
            range: NSRange(content.startIndex..<content.endIndex, in: content),
            withTemplate: "[$2]($1)"
        )
        
        content = content.replacingOccurrences(of: "<h1>", with: "# ")
        content = content.replacingOccurrences(of: "<h2>", with: "## ")
        content = content.replacingOccurrences(of: "<h3>", with: "### ")
        content = content.replacingOccurrences(of: "<h4>", with: "#### ")
        content = content.replacingOccurrences(of: "<h5>", with: "##### ")
        content = content.replacingOccurrences(of: "<h6>", with: "###### ")
        content = content.replacingOccurrences(of: "</h1>", with: "\r\n")
        content = content.replacingOccurrences(of: "</h2>", with: "\r\n")
        content = content.replacingOccurrences(of: "</h3>", with: "\r\n")
        content = content.replacingOccurrences(of: "</h4>", with: "\r\n")
        content = content.replacingOccurrences(of: "</h5>", with: "\r\n")
        content = content.replacingOccurrences(of: "</h6>", with: "\r\n")
        content = content.replacingOccurrences(of: "<strong>", with: "**")
        content = content.replacingOccurrences(of: "</strong>", with: "**")
        content = content.replacingOccurrences(of: "<b>", with: "**")
        content = content.replacingOccurrences(of: "</b>", with: "**")
        content = content.replacingOccurrences(of: "<em>", with: "*")
        content = content.replacingOccurrences(of: "</em>", with: "*")
        content = content.replacingOccurrences(of: "\t", with: "    ")
        content = content.replacingOccurrences(of: "<code>", with: "\r\n```")
        content = content.replacingOccurrences(of: "</code>", with: "```\r\n")
        content = content.replacingOccurrences(of: "<ul>", with: "\r\n")
        content = content.replacingOccurrences(of: "</ul>", with: "\r\n")
        content = content.replacingOccurrences(of: "<li>", with: "- ")
        content = content.replacingOccurrences(of: "</li>", with: "")
        content = content.replacingOccurrences(of: "<ol>", with: "1. ")
        content = content.replacingOccurrences(of: "</ol>", with: "")
        content = content.replacingOccurrences(of: "<pre>", with: "\r\n```")
        content = content.replacingOccurrences(of: "</pre>", with: "```\r\n")
        content = content.replacingOccurrences(of: "<i>", with: "_")
        content = content.replacingOccurrences(of: "</i>", with: "_")
        
        var lines = [String]()
        lines.append("---")
        //lines.append("layout: post")
        lines.append("title: |")
        lines.append("    \(title)")
        lines.append("date: \(dateFormatter.string(from: dateAdd))")
        // lines.append("image: ") // TODO:
        lines.append("authors: [\(user)]")
        lines.append("tags: [\(tags.map({ $0.lowercased() }).joined(separator: ", "))]")
        lines.append("categories: [\(blog.title)]")
        lines.append("permalink: \(makePermalink(blog: blog))")
        lines.append("blogcat: \(blog.title)")
        lines.append("excerpt_separator: <!--cut-->")
        lines.append("---")
        lines.append("")
        lines.append(content)
        lines.append("")
        
        let roots = comments.filter { $0.pid == nil }
        if !roots.isEmpty {
            lines.append("### Комментарии")
            writeComments(level: 1, to: &lines, items: roots, full: comments)
            lines.append("")
        }
        
        return lines.joined(separator: "\r\n")
    }
    
    private func makePermalink(blog: Blog) -> String {
        let components = [
            "",
            "blog",
            blog.link,
            "\(id).html"
        ]
        return components.compactMap { $0 }.joined(separator: "/")
    }
}

private func pad(level: Int) -> String {
    return String(repeating: ">", count: level)
}

private func writeComments(level: Int, to lines: inout [String], items: [Comment], full: [Comment]) {
    for item in items {
        lines.append("")

        let dtrepr = humanReadableFormatter.string(from: item.date)
        lines.append("\(pad(level: level)) **\(item.login), \(dtrepr)**")
        lines.append("\(pad(level: level)) \(item.text)")
        
        let subitems = full.filter {
            if let pid = $0.pid, pid == item.id {
                return true
            } else {
                return false
            }
        }
        if !subitems.isEmpty {
            writeComments(level: level + 1, to: &lines, items: subitems, full: full)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.timeZone = TimeZone(secondsFromGMT: 0)
    return fmt
}()

private let parseFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.timeZone = TimeZone(secondsFromGMT: 0)
    return fmt
}()

private let humanReadableFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "d MMM yyyy, HH:mm"
    fmt.locale = Locale(identifier: "ru_RU")
    fmt.timeZone = TimeZone(secondsFromGMT: 3 * 3600)
    return fmt
}()
