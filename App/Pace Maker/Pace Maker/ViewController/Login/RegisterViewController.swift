//
//  RegisterViewController.swift
//  Pace Maker
//
//  Created by Kyungho on 2021/05/16.
//

import UIKit
import UnderKeyboard

class RegisterViewController: UIViewController {
    
    let underKeyboardLayoutConstraint = UnderKeyboardLayoutConstraint()

    var isCorrectEmailFormat: Bool = false
    var isCorrectPasswordFormat: Bool = false
    var isPasswordSame: Bool = false
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var anotherPassword: UITextField!
    @IBOutlet var inputTextFields: [UITextField]!
    
    @IBOutlet weak var registerView: UIView!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        underKeyboardLayoutConstraint.setup(bottomLayoutConstraint, view: view)
        activityIndicator.hidesWhenStopped = true
        setTextFields()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.email.becomeFirstResponder()
        }
    }
    
    func setTextFields() {
        self.email.delegate = self
        self.password.delegate = self
        self.anotherPassword.delegate = self
        
        for field in inputTextFields {
            field.layer.cornerRadius = 6
            field.layer.borderWidth = 1
            field.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    
    @IBAction func emailEditingDidChanged(_ sender: UITextField) {
        print("editing changed")
        guard let text = sender.text else { return }
        if text.isValidEmail() {
            isCorrectEmailFormat = true
            sender.layer.borderColor = UIColor.lightGray.cgColor
        }else {
            isCorrectEmailFormat = false
            sender.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    @IBAction func passwordEditingDidChanged(_ sender: UITextField) {
        print("editing changed")
        guard let text = sender.text else { return }
        if text.isValidPassword {
            isCorrectPasswordFormat = true
            sender.layer.borderColor = UIColor.lightGray.cgColor
        }else {
            isCorrectPasswordFormat = false
            sender.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    @IBAction func anotherPasswordEditingDidChanged(_ sender: UITextField) {
        if (anotherPassword.text != nil) && anotherPassword.text == password.text{
            isPasswordSame = true
            sender.layer.borderColor = UIColor.lightGray.cgColor
        }else {
            isPasswordSame = false
            sender.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    @IBAction func registerAction(_ sender: Any) {
        registerNewUser()
    }
    
    func registerNewUser(){
        if verifyCorrectInputFormat() {
            handleRegisterSuccess()
        }else {
            handleRegisterFailure()
        }
    }
    
    func handleRegisterSuccess() {
        verifyNotDuplicatedEmail()
    }

    func handleRegisterFailure() {
        hapticfeedbackGenerator.notificationOccurred(.error)
        registerView.shake()
    }
    
    func verifyCorrectInputFormat() -> Bool {
        if !isCorrectEmailFormat{
            alertIncorrectInputFormat(with: "이메일", and:"")
            return false
        } else if !isCorrectPasswordFormat{
            alertIncorrectInputFormat(with: "비밀번호",and: "특수문자를 포함한 6 - 12 글자")
            return false
        }else if !isPasswordSame {
            alertIncorrectInputFormat(with: "일치하지 않는 비밀번호",and: "다시 입력한 비밀번호가 다릅니다.")
            return false
        }
        return true
    }

    func verifyNotDuplicatedEmail() {
        activityIndicator.startAnimating()
        realtimeReference.reference(withPath: "user")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: self.email.text)
            .observeSingleEvent(of: .value) { snapshot in
                self.activityIndicator.stopAnimating()
                
                let found: Bool = snapshot.childrenCount != 0
                if found {
                    self.alertDuplicateEmail()
                }else {
                    self.continueRegisterAction()
                }
            }
    }
    
    func alertIncorrectInputFormat(with message: String, and information: String){
        let message = "\(message) 형식이 올바르지 않습니다\n\(information)"
        let alertController = UIAlertController(title: "",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alertDuplicateEmail(){
        let message = "이미 이메일 \"(\(email.text!))\"\n 로 등록된 사용자가 있습니다."
        print(message)
        let alertController = UIAlertController(title: "이미 가입된 이메일",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "패스워드 찾기", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func continueRegisterAction(){
        // email NOT duplicated
        // continue registering
        hapticfeedbackGenerator.notificationOccurred(.success)
        performSegue(withIdentifier: "ContinueRegister", sender: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? RegisterDetailViewController {
            nextViewController.email = email.text
            nextViewController.password = password.text
        }
    }
    
    var isCorrectFormat : Bool {
        get{
            return isCorrectEmailFormat && isCorrectPasswordFormat
        }
    }

}

extension RegisterViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
            case 1:
                password.becomeFirstResponder()
            case 2:
                anotherPassword.becomeFirstResponder()
            case 3:
                registerNewUser()
            default:
                break
        }
        return true
    }
}


extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[a-zA-Z_0-9\\-_,;.:#+*?=!§$%&/()@]+$", options: .caseInsensitive)
            if(regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) != nil){
                
                if(self.count>=6 && self.count<=20){
                    return true
                }else{
                    return false
                }
            }else{
                return false
            }
        } catch {
            return false
        }
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}
