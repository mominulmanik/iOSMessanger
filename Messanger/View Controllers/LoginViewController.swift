
import UIKit
import FirebaseAuth
import Firebase

class LoginViewController: UIViewController {
  
  @IBOutlet var actionButton: UIButton!

  @IBOutlet var PasswordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
  @IBOutlet var actionButtonBackingView: UIView!
  @IBOutlet weak var fieldBackingView: UIView!

  //@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
    fieldBackingView.layer.cornerRadius = 10
    
    PasswordField.tintColor = .primary
    emailField.tintColor = .primary
    //registerForKeyboardNotifications()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    //PasswordField.becomeFirstResponder()
  }
  
  // MARK: - Actions
  
  @IBAction func actionButtonPressed() {
    signIn()
  }
  
  @objc private func textFieldDidReturn() {
    signIn()
  }
  
  // MARK: - Helpers
  
//  private func registerForKeyboardNotifications() {
//    NotificationCenter.default.addObserver(
//      self,
//      selector: #selector(keyboardWillShow(_:)),
//      name: UIResponder.keyboardWillShowNotification,
//      object: nil
//    )
//    NotificationCenter.default.addObserver(
//      self,
//      selector: #selector(keyboardWillHide(_:)),
//      name: UIResponder.keyboardWillHideNotification,
//      object: nil
//    )
//  }
  
  private func signIn() {
    guard let password = PasswordField.text, !password.isEmpty else {
      showMissingNameAlert(text: "Password")
      return
    }
    guard let email = emailField.text, !email.isEmpty else {
      showMissingNameAlert(text: "Email Address")
      return
    }
    
    PasswordField.resignFirstResponder()
    emailField.resignFirstResponder()
    Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
        guard let result = result else{ return}
        let user = result.user
        self.show(ChannelsViewController.init(currentUser: user), sender: nil)
    }
    
  }
  
    private func showMissingNameAlert(text: String) {
    let ac = UIAlertController(title: "Display Name Required", message: "Please enter a "+text+".", preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
      DispatchQueue.main.async {
        self.PasswordField.becomeFirstResponder()
      }
    }))
    present(ac, animated: true, completion: nil)
  }
  
//  // MARK: - Notifications
//
//  @objc private func keyboardWillShow(_ notification: Notification) {
//    guard let userInfo = notification.userInfo else {
//      return
//    }
//    guard let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
//      return
//    }
//    guard let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
//      return
//    }
//    guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
//      return
//    }
//
//    let options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve << 16)
//    //bottomConstraint.constant = keyboardHeight + 20
//
//    UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
//      self.view.layoutIfNeeded()
//    }, completion: nil)
//  }
//
//  @objc private func keyboardWillHide(_ notification: Notification) {
//    guard let userInfo = notification.userInfo else {
//      return
//    }
//    guard let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
//      return
//    }
//    guard let keyboardAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
//      return
//    }
//
//    let options = UIView.AnimationOptions(rawValue: keyboardAnimationCurve << 16)
//    //bottomConstraint.constant = 20
//
//    UIView.animate(withDuration: keyboardAnimationDuration, delay: 0, options: options, animations: {
//      self.view.layoutIfNeeded()
//    }, completion: nil)
//  }
//
}
