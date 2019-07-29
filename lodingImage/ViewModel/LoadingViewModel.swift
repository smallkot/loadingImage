//
//  LodingViewModel.swift
//  lodingImage
//
//  Created by smallkot on 7/28/19.
//  Copyright © 2019 smallkot. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AlamofireImage
import Alamofire

class LoadingViewModel {
  var imageUrlObsevable = BehaviorSubject<String?>(value: "https://upload.wikimedia.org/wikipedia/commons/3/3d/LARGE_elevation.jpg")
  var imageObservable = BehaviorSubject<UIImage?>(value: nil)
  var countObservable = BehaviorSubject<Int>(value: 0)
  var progress = BehaviorSubject<Bool>(value: false)
  var progressCount = BehaviorSubject<Int>(value: 0)
  var changeUrl = BehaviorSubject<Bool>(value: false)
  var downloadedImage = BehaviorSubject<Bool>(value: false)
  
  var count = 0
  
  let imageDownloader = ImageDownloader(sessionManager: SessionManager.default)
  var request: RequestReceipt?
  let disposeBag = DisposeBag()
  
  let placeholderImage = UIImage(named: "image_placeholder")
  
  init() {
    imageUrlObsevable
      .subscribe(onNext: { [weak self] (_) in
        self?.changeUrl.onNext(true)
      })
      .disposed(by: disposeBag)
    
    imageObservable.onNext(placeholderImage)
  }
  
  func countString() -> Observable<String> {
    return countObservable
      .observeOn(MainScheduler.instance)
      .map({ (count) -> String in
        return "\(count)"
      })
  }
  
  func plusCount() {
    count += 1
    countObservable.onNext(count)
  }
  
  func startDownloadImage() {
    guard !(try! progress.value()) else { return }
    guard let url = try? imageUrlObsevable.value() else { return }
    guard let urlImage = URL(string: url) else { return }
    progressCount.onNext(0)
    imageObservable.onNext(nil)
    progress.onNext(true)
    changeUrl.onNext(false)
    
    let urlRequest = URLRequest(url: urlImage)
    
    request = imageDownloader
      .download(
        urlRequest,
        receiptID: UUID().uuidString,
        filter: nil,
        progress: { [weak self] (progress) in
          self?.progressCount.onNext(Int(progress.fractionCompleted*100))
        },
        progressQueue: DispatchQueue.global()) { [weak self] (response) in
          self?.progress.onNext(false)
          if let data = response.data {
            self?.downloadedImage.onNext(true)
            self?.imageObservable.onNext(UIImage(data: data))
          } else {
            self?.imageObservable.onNext(self?.placeholderImage)
          }
        }
  }
  
  func cancelDownloadImage() {
    guard let request = request else { return }
    progress.onNext(false)
    downloadedImage.onNext(false)
    imageObservable.onNext(placeholderImage)
    imageDownloader.cancelRequest(with: request)
  }
  
  func enableStart() -> Driver<Bool> {
    let progressDriver = progress.asDriver(onErrorJustReturn: false)
    
    let changeUrlDriver = changeUrl.asDriver(onErrorJustReturn: false)
    let downloadedImageDriver = downloadedImage.asDriver(onErrorJustReturn: false)
    
    return Driver.combineLatest(countDriver(), progressDriver, changeUrlDriver, downloadedImageDriver)
      { (countDriver, progressDriver, changeUrlDriver, downloadedImageDriver) -> Bool in
        guard countDriver else { return false }
        guard !progressDriver else { return false }
        guard downloadedImageDriver else { return true }
        
        return changeUrlDriver
      }
      .distinctUntilChanged()
  }
  
  func enableCancel() -> Driver<Bool> {
    let progressDriver = progress.asDriver(onErrorJustReturn: false)
    
    return Driver.combineLatest(countDriver(), progressDriver)
      { (countDriver, progressDriver) -> Bool in
        guard countDriver else { return false }
        return progressDriver
      }
      .distinctUntilChanged()
  }
  
  private func countDriver() -> Driver<Bool> {
    return countObservable
      .flatMap({ (count) -> Driver<Bool> in
        return Driver<Bool>.just(count%2 != 0)
      })
      .asDriver(onErrorJustReturn: false)
  }
}
