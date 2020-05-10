

import Firebase
import MessageKit
import FirebaseFirestore

struct Message: MessageType {
  var sender: SenderType
  var kind: MessageKind{
    if let image = image {
      return .photo(image)
    } else {
      return .text(content)
    }
  }
  let id: String?
  let content: String
  let sentDate: Date

  var messageId: String {
    return id ?? UUID().uuidString
  }

  var image: UIImage? = nil
  var downloadURL: URL? = nil

  init(user: User, content: String) {
    sender = Sender(senderId: user.uid, displayName: "Mominul")
    self.content = content
    sentDate = Date()
    id = nil
  }
  
  init(user: User, image: UIImage) {
    sender = Sender(senderId: user.uid, displayName: "Mominul")
    self.image = image
    content = ""
    sentDate = Date()
    id = nil
  }

  init?(document: QueryDocumentSnapshot) {
    let data = document.data()

    guard let senderID = data["senderID"] as? String else {
      return nil
    }
    guard let senderName = data["senderName"] as? String else {
      return nil
    }

    guard let sendDate = data["created"] as? Timestamp else {
      return nil
    }

    id = document.documentID

    self.sentDate = sendDate.dateValue()
    sender = Sender(senderId: senderID, displayName: senderName)

    if let content = data["content"] as? String {
      self.content = content
      downloadURL = nil
    } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
      downloadURL = url
      content = ""
    } else {
      return nil
    }
  }
  
}

extension Message: DatabaseRepresentation {
  
  var representation: [String : Any] {
    var rep: [String : Any] = [
      "created": sentDate,
      "senderID": sender.senderId,
      "senderName": sender.displayName
    ]
    
    if let url = downloadURL {
      rep["url"] = url.absoluteString
    } else {
      rep["content"] = content
    }
    
    return rep
  }
  
}

extension Message: Comparable {
  
  static func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
  }
  
  static func < (lhs: Message, rhs: Message) -> Bool {
    return lhs.sentDate < rhs.sentDate
  }
  
}

extension UIImage: MediaItem {
  public var url: URL? { return nil }
  public var image: UIImage? { return self }
  public var placeholderImage: UIImage { return self }
  public var size: CGSize { return  CGSize.zero }
}
