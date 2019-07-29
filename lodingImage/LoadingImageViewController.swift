//
//  ViewController.swift
//  lodingImage
//
//  Created by smallkot on 7/26/19.
//  Copyright © 2019 smallkot. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import MBCircularProgressBar

class LoadingImageViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var urlTextField: UITextField!
  @IBOutlet weak var countLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var plusCountButton: UIButton!
  @IBOutlet weak var progressBar: MBCircularProgressBarView!
  
  var loadingViewModel = LoadingViewModel()
  
  let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    
    setupCloseKeyboard()
    setupBindUI()
  }
  
  // MARK: - SETUP BIND
  func setupBindUI() {
    // urlTextField
    loadingViewModel.imageUrlObsevable
      .bind(to: urlTextField.rx.text)
      .disposed(by: disposeBag)
    
    urlTextField.rx.text
      .bind(to: loadingViewModel.imageUrlObsevable)
      .disposed(by: disposeBag)
    
    // countLabel
    loadingViewModel.countString()
      .bind(to: countLabel.rx.text)
      .disposed(by: disposeBag)
    
    
    // start button
    loadingViewModel
      .enableStart()
      .drive(startButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    // cancel button
    loadingViewModel
      .enableCancel()
      .drive(cancelButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    // imageView
    loadingViewModel.imageObservable
      .bind(to: imageView.rx.image)
      .disposed(by: disposeBag)
    
    // progressBar
    loadingViewModel
      .progress
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: {[weak self] (isProgress) in
        self?.progressBar.isHidden = !isProgress
      })
      .disposed(by: disposeBag)
    
    loadingViewModel
      .progressCount
      .asDriver(onErrorJustReturn: 0)
      .drive(onNext: { [weak self] (precent) in
        self?.progressBar.value = CGFloat(precent)
      })
      .disposed(by: disposeBag)
  }
  
  func setupCloseKeyboard() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
    view.addGestureRecognizer(tap)
  }
  
  @objc
  func closeKeyboard() {
    view.endEditing(true)
  }

  @IBAction func onStart(_ sender: Any) {
    loadingViewModel.startDownloadImage()
  }
  
  @IBAction func onCancel(_ sender: Any) {
    loadingViewModel.cancelDownloadImage()
  }
  
  @IBAction func onPlusCount(_ sender: Any) {
    loadingViewModel.plusCount()
  }
  
}

extension LoadingImageViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return textField.returnKeyType == .done
  }
}
