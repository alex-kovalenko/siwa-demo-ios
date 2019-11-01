/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Login view controller.
*/

import UIKit
import AuthenticationServices

class LoginViewController: UIViewController {
    private let childname = "child"
    private var isChild: Bool {
        return (Bundle.main.infoDictionary!["CFBundleName"] as! String).lowercased() == childname
    }

    private var keychainGroup: String {
        return isChild ? "com.sampleapp.child-one.siwa" : "com.sampleapp.master.siwa"
    }


    @IBOutlet weak var loginTitle: UILabel!
    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginTitle.text = Bundle.main.infoDictionary!["CFBundleName"] as? String
        setupProviderLoginView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlows()
    }
    
    func setupProviderLoginView() {
        let authorizationButton = ASAuthorizationAppleIDButton()
        authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
        self.loginProviderStackView.addArrangedSubview(authorizationButton)
    }
    
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
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email

            var response: String = "No Response"

            // Create an account in your system.
            if let authorizationCode = appleIDCredential.authorizationCode {
                response = Link.create(with: authorizationCode, andBundleID: Bundle.main.bundleIdentifier!)
                print(response)
            }

            // For the purpose of this demo app, store the userIdentifier in the keychain.
            do {
                try KeychainItem(service: keychainGroup, account: "userIdentifier").saveItem(userIdentifier)
            } catch {
                print("Unable to save userIdentifier to keychain.")
            }
            
            // For the purpose of this demo app, show the Apple ID credential information in the ResultViewController.
            if let viewController = self.presentingViewController as? ResultViewController {
                DispatchQueue.main.async {
                    viewController.userIdentifierLabel.text = userIdentifier
                    if let givenName = fullName?.givenName {
                        viewController.givenNameLabel.text = givenName
                    }
                    if let familyName = fullName?.familyName {
                        viewController.familyNameLabel.text = familyName
                    }
                    if let email = email {
                        viewController.emailLabel.text = email
                    }

                    viewController.resultTextView.text = response

                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
                let alertController = UIAlertController(title: "Keychain Credential Received",
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
