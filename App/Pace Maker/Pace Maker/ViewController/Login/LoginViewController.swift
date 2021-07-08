//
//  LoginViewController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/05/16.
//

import UIKit

import AuthenticationServices
import Firebase
import UnderKeyboard
import NotificationBannerSwift

class LoginViewController: UIViewController {

    let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        activityIndicator.hidesWhenStopped = true
        setupProviderLoginView()
        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        performExistingAccountSetupFlows()
    }
    
    @IBAction func loginAction(_ sender: Any) {
        guard let _ = email.text,
              let password = password.text else { return }
        activityIndicator.startAnimating()
        
        realtimeReference.reference(withPath: "user")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: email.text)
            .observeSingleEvent(of: .value) { snapshot in
                
                if snapshot.childrenCount == 0 {
                    // no corresponding email
                    self.handleLoginDidFailure()
                }else {
                    print(snapshot)
                    for child in snapshot.children.allObjects as! [DataSnapshot]{
                        let userCredential = child.childSnapshot(forPath: "passwd").value as! String
                        if userCredential == password{
                            let UID = child.key
                            self.handleLoginDidSuccess(with: UID)
                            // login success
                        }else {
                            self.handleLoginDidFailure()
                            // login fail
                        }
                    }
                }
                self.activityIndicator.stopAnimating()
            }
    }
    
    func handleLoginDidFailure() {

        hapticfeedbackGenerator.notificationOccurred(.error)
        
        let message = "이메일 또는 패스워드가 잘못되었습니다. 다시 한 번 확인해 주세요"
        let alertController = UIAlertController(title: "로그인 실패",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "다시 입력", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func handleLoginDidSuccess(with user: String?) {
        hapticfeedbackGenerator.notificationOccurred(.success)
        
        guard let user = user else { return }
        userId = user
        performSegue(withIdentifier: "unwindToHome", sender: nil)
    }
}

//
extension LoginViewController: ASAuthorizationControllerDelegate {
    /// - Tag: add_appleid_button
    func setupProviderLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton(type: .signUp, style: .whiteOutline)
        
        //        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        self.loginProviderStackView.addArrangedSubview(authorizationButton)
    }
    
    // - Tag: perform_appleid_password_request
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
        
        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVC = segue.destination as? HomeViewController {
            destVC.loginRequested = true
        }
    }
    
    /// - Tag: perform_appleid_request
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                
                // Create an account in your system.
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                print("User ID : \(userIdentifier)")
                print("User Email : \(email ?? "")")
                print("User Name : \((fullName?.givenName ?? "") + (fullName?.familyName ?? ""))")
                
                // For the purpose of this demo app, store the `userIdentifier` in the keychain.
//                self.saveUserInKeychain(userIdentifier)
                
                // For the purpose of this demo app, show the Apple ID credential information in the `ResultViewController`.
//                self.showResultViewController(userIdentifier: userIdentifier, fullName: fullName, email: email)
                
            case let passwordCredential as ASPasswordCredential:
                
                // Sign in using an existing iCloud Keychain credential.
                let username = passwordCredential.user
                let password = passwordCredential.password
                
                // For the purpose of this demo app, show the password credential as an alert.
                DispatchQueue.main.async {
                    self.showPasswordCredentialAlert(username: username, password: password)
                }
                
            default:
                break
        }
    }
    
    private func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
