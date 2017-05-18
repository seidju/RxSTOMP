//
//  ExampleViewController.swift
//  RxSTOMPExample
//
//  Created by Pavel Shatalov on 18.05.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSTOMP

class ExampleViewController: UIViewController {
    
    var viewModel: ExampleViewModel?
    
    @IBOutlet private weak var loginTextField: UITextField!
    @IBOutlet private weak var passcodeTextField: UITextField!
    @IBOutlet private weak var connectButton: UIButton!
    fileprivate let disposeBag = DisposeBag()
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRx()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //MARK: - Setup Rx
    
    func setupRx() {
        self.connectButton.rx.tap
            .filter {[weak self] in
                guard let sSelf = self else { return false }
                guard let login = sSelf.loginTextField.text, let passcode = sSelf.passcodeTextField.text else { return false}
                
                return login.characters.count > 0 && passcode.characters.count > 0
            }.subscribe(onNext: {[weak self] in
                guard let sSelf = self else { return }
                guard let viewModel = sSelf.viewModel else { return }
                guard let login = sSelf.loginTextField.text, let passcode = sSelf.passcodeTextField.text else { return }
                viewModel.connect(login: login, passcode: passcode)
            }).addDisposableTo(self.disposeBag)
    }
}

