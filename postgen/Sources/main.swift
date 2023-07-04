
import Foundation
import MySQLNIO

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
let eventLoop = eventLoopGroup.any()

do {
    let connection = try await MySQLConnection.connect(
        to: .makeAddressResolvingHost("localhost", port: 3306),
        username: "<user>",
        database: "<db>",
        password: "<password>",
        on: eventLoop
    ).get()
    defer { try? connection.close().wait() }
    
    let blogsRecordset = try await connection.query("SELECT B.blog_id as BID, B.blog_title as Title, B.blog_url as URL from itw66_blog as B").get()
    let blogs = blogsRecordset
        .compactMap { row in
            guard let bid = row.column("BID")?.int,
                  let title = row.column("Title")?.string else {
                return nil
            }
            
            return Blog(
                id: bid,
                title: title,
                link: row.column("URL")?.string
            )
        }
        .reduce(into: [Int: Blog]()) { res, item in
            res[item.id] = item
        }
    
    var knownUserIds = Set<Int>()
        
    let topics = try await connection.query("""
        SELECT T.topic_id AS TID,
            T.blog_id AS BID,
            T.topic_title AS Title,
            T.topic_date_add AS DateAdd,
            T.user_id AS UID,
            U.user_login as User
        FROM itw66_topic AS T
            LEFT JOIN itw66_user as U ON T.user_id = U.user_id
        WHERE T.topic_type = 'topic'
    """).get()
    for topic in topics {
        guard
            let tid = topic.column("TID")?.string,
            let bid = topic.column("BID")?.int,
            let title = topic.column("Title")?.string,
            let dateAdd = topic.column("DateAdd")?.date,
            let userId = topic.column("UID")?.int,
            let user = topic.column("User")?.string
        else {
            continue
        }
        
        knownUserIds.insert(userId)
        
        let tagsResult = try await connection.query("SELECT topic_tag_text AS Text FROM itw66_topic_tag WHERE topic_id = ?", [MySQLData(string: tid)]).get()
        let tags = tagsResult.compactMap { $0.column("Text")?.string?.replacingOccurrences(of: "?", with: "") }
        
        let contentResult = try await connection.query("SELECT TC.topic_text_source as Text FROM itw66_topic_content AS TC WHERE TC.topic_id = ?", [MySQLData(string: tid)]).get()
        guard let content = contentResult.compactMap({ $0.column("Text")?.string }).first else {
            continue
        }
        
        let commentsResult = try await connection.query("""
            SELECT
                C.comment_id AS CID,
                C.comment_pid AS CPID,
                C.comment_text AS text,
                C.comment_date AS date,
                U.user_login AS login
            FROM itw66_comment AS C
                LEFT JOIN itw66_user AS U ON C.user_id = U.user_id
            WHERE C.target_type = 'topic' AND c.target_id = ? AND C.comment_publish = 1
        """, [MySQLData(string: tid)]).get()
        let comments: [Comment] = commentsResult
            .compactMap {
                guard let id = $0.column("CID")?.int,
                      let text = $0.column("text")?.string,
                      let login = $0.column("login")?.string,
                      let date = $0.column("date")?.date
                else {
                    return nil
                }
                let pid = $0.column("CPID")?.int
                return Comment(id: id, pid: pid, login: login, text: text, date: date)
            }
        
        let post = Post(
            id: tid,
            blogId: bid,
            title: title,
            dateAdd: dateAdd,
            user: user,
            tags: tags,
            text: content,
            comments: comments
        )
        
        guard let blog = blogs[post.blogId] else {
            continue
        }
        
        let fileUrl = URL(fileURLWithPath: "_posts/\(post.jekyllFileName())")
        print(fileUrl)
        try post.asJekyll(blog: blog).write(to: fileUrl, atomically: true, encoding: .utf8)
    }
    
    //print("uids: \(knownUserIds)")
    
    let usersResult = try await connection.query("SELECT U.user_id AS UID, U.user_login AS login, U.user_profile_name AS realName, U.user_mail AS email, U.user_profile_site AS url FROM itw66_user AS U").get()
    let users: [User] = usersResult
        .compactMap {
            guard let uid = $0.column("UID")?.int,
                  let login = $0.column("login")?.string else {
                return nil
            }
            let realName = $0.column("realName")?.string
            let email = $0.column("email")?.string
            let url = $0.column("url")?.string
            return User(id: uid, login: login, realName: realName, email: email, url: url)
        }
        .filter {
            knownUserIds.contains($0.id)
        }
    let authorsUrl = URL(fileURLWithPath: "_data/authors.yml")
    print(authorsUrl)
    try users.asJekyllAuthors().write(to: authorsUrl, atomically: true, encoding: .utf8)
    
    print("Ok")
} catch {
    print("Oops: \(error)")
}
