//
//  ChatViewController.swift
//  Messanger
//
//  Created by Md Mominul islam on 1/5/20.
//  Copyright © 2020 Bjit. All rights reserved.
//


import UIKit
import Firebase
import MessageKit
import FirebaseFirestore
import InputBarAccessoryView
import Photos
import SDWebImage

class ChatViewController: MessagesViewController {
  
  private let user: User
  var currentUser: User = Auth.auth().currentUser!
  private let channel: Channel
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  private let db = Firestore.firestore()
  private var reference: CollectionReference?
  private var isSendingPhoto = false {
    didSet {
      DispatchQueue.main.async {
        self.messageInputBar.leftStackViewItems.forEach { item in
            item.inputBarAccessoryView?.isUserInteractionEnabled = self.isSendingPhoto
        }
      }
    }
  }
  private let storage = Storage.storage().reference()
  
  init(user: User, channel: Channel) {
    self.user = user
    self.channel = channel
    super.init(nibName: nil, bundle: nil)
    
    title = channel.name
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    messageListener?.remove()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = false
    guard let id = channel.id else {
        navigationController?.popViewController(animated: true)
        return
    }
    self.view.backgroundColor = UIColor(red: 115/255, green: 184/255, blue: 1.0, alpha: 1)
    reference = db.collection(["channels", id, "thread"].joined(separator: "/"))
    navigationItem.largeTitleDisplayMode = .never

    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = .primary
    messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    let cameraItem = InputBarButtonItem(type: .system)
    cameraItem.tintColor = .primary
    cameraItem.image = UIImage(systemName: "camera.fill")

    // 2
    cameraItem.addTarget(
      self,
      action: #selector(cameraButtonPressed),
      for: .primaryActionTriggered
    )
    cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)

    messageInputBar.leftStackView.alignment = .center
    messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

    // 3
    messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
    messageInputBar.delegate = self
    messagesCollectionView.backgroundColor = UIColor(red: 115/255, green: 184/255, blue: 1.0, alpha: 1)
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    messageListener = reference?.addSnapshotListener({ (queryShot, error) in
        guard let snapShot = queryShot else{
            print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
            return
        }
        snapShot.documentChanges.forEach { (change) in
            self.handleDocumentChange(change)
        }
    })
  }

    func insertNewMessage(_ message: Message){
        guard !messages.contains(message) else {
            return
        }
        messages.append(message)
        messages.sort()
        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        messagesCollectionView.reloadData()
        if shouldScrollToBottom{
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }

    private func handleDocumentChange (_ change: DocumentChange){
        guard var message = Message(document: change.document) else {
          return
        }
        switch change.type {
        case .added:
            if let url = message.downloadURL{
                downloadImage(at: url) { (image) in
                    guard let image = image else{
                        return
                    }
                    message.image = image
                    self.insertNewMessage(message)
                }
            }else{
                insertNewMessage(message)
            }
        default:
            break
        }
    }

    private func save(_ message: Message) {
      reference?.addDocument(data: message.representation) { error in
        if let e = error {
          print("Error sending message: \(e.localizedDescription)")
          return
        }
        
        self.messagesCollectionView.scrollToBottom()
      }
    }

    // MARK: - Actions

    @objc private func cameraButtonPressed() {
      let picker = UIImagePickerController()
      picker.delegate = self

      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        picker.sourceType = .camera
      } else {
        picker.sourceType = .photoLibrary
      }

      present(picker, animated: true, completion: nil)
    }

    //MARK: Upload image to firebase storage
    private func uploadImage(_ image: UIImage, to channel: Channel, completion: @escaping(URL?)-> Void){
        guard let channelId = channel.id else { return }
        guard let scaledImage = image.image(scaledTo: CGSize(width: CGFloat(200), height: CGFloat(200))), let data = scaledImage.jpegData(compressionQuality: 0.4) else { completion(nil)
            return
        }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let ref = storage.child(channelId).child(imageName+".jpeg")
        ref.putData(data, metadata: nil) { (meta, error) in
            ref.downloadURL(completion: { (url, error) in
                completion(url)
            })
            print(error.debugDescription)
        }
    }

    private func sendPhoto(_ image: UIImage) {
      isSendingPhoto = true
      
      uploadImage(image, to: channel) { [weak self] url in
        guard let `self` = self else {
          return
        }
        self.isSendingPhoto = false
        
        guard let url = url else {
          return
        }
        
        var message = Message(user: self.user, image: image)
        message.downloadURL = url
        
        self.save(message)
        self.messagesCollectionView.scrollToBottom()
      }
    }

    //MARK: Download image from firebade Storgae
    private func downloadImage(at url: URL, completion: @escaping (UIImage?)-> Void){
        let ref = Storage.storage().reference(forURL: url.absoluteString)
        let megaByte = Int64(10*1024*1024)
        ref.getData(maxSize: megaByte) { (data, error) in
            guard let imageData = data else {
                completion(nil)
                return
            }
            completion(UIImage(data: imageData))
        }
    }
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
  func backgroundColor(for message: MessageType, at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) -> UIColor {
    
    // 1
    return isFromCurrentSender(message: message) ? .primary : .incomingMessage
  }

  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) -> Bool {

    // 2
    return true
  }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    //If it's current user show current user photo.
    if message.sender.senderId == currentUser.uid {
    SDWebImageManager.shared.loadImage(with: currentUser.photoURL, options: .highPriority, progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
    avatarView.image = image
    }
    } else {
    avatarView.image = UIImage(named: "Male-Placeholder")
    }
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}

//MARK: - MessagesDisplayDataSource

extension ChatViewController: MessagesDataSource{
    func currentSender() -> SenderType {
        return Sender(senderId: user.uid, displayName: "Manik")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
      return messages.count
    }

    func cellTopLabelAttributedText(for message: MessageType,
      at indexPath: IndexPath) -> NSAttributedString? {

        let name = "Manik"
      return NSAttributedString(
        string: name,
        attributes: [
          .font: UIFont.preferredFont(forTextStyle: .caption1),
          .foregroundColor: UIColor(white: 0.3, alpha: 1)
        ]
      )
    }
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {

  func avatarSize(for message: MessageType, at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) -> CGSize {

    // 1
    return .zero
  }

  func footerViewSize(for message: MessageType, at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) -> CGSize {

    // 2
    return CGSize(width: 10, height: 10)
  }

  func heightForLocation(message: MessageType, at indexPath: IndexPath,
    with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {

    // 3
    return .zero
  }
}
// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(user: user, content: text)
        save(message)
        inputBar.inputTextView.text = ""
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)
    
    // 1
    if let asset = info[.phAsset] as? PHAsset {
      let size = CGSize(width: 500, height: 500)
      PHImageManager.default().requestImage(
        for: asset,
        targetSize: size,
        contentMode: .aspectFit,
        options: nil) { result, info in
          
        guard let image = result else {
          return
        }
        
        self.sendPhoto(image)
      }

    // 2
    } else if let image = info[.originalImage] as? UIImage {
      sendPhoto(image)
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}
