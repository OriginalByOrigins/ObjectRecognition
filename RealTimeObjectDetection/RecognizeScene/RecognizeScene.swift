//
//  RecognizeScene.swift
//  RealTimeObjectDetection
//
//  Created by Harry Cao on 16/7/17.
//  Copyright © 2017 Harry Cao. All rights reserved.
//

import UIKit
import AVKit
import Vision

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  @objc func openGallery() {
    // Stop the capture process
    isProcessing = false
    stopCaptureSession()
    
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    present(imagePicker, animated: true, completion: nil)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard
      let selectedImage = info["UIImagePickerControllerOriginalImage"] as? UIImage,
      let imageUrl = info["UIImagePickerControllerImageURL"] as? URL
      else { return }
    
    pickerImageView.image = selectedImage
    self.view.addSubview(pickerImageView)
    
    picker.dismiss(animated: true, completion: nil)
    
    analyseImage(forImageUrl: imageUrl)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    setupCaptureSession()
  }
  
  func analyseImage(forImageUrl imageUrl: URL) {
    /*
     // MARK: don't use Vision, but need to convert to 224x224 CVPixelBuffer
     do {
     let model = GoogleNerPlaces()
     let predict = try model.prediction(image: myPixelBuffer) // Need to convert selectedImage to 224x224 CVPixelBuffer
     print(predict.classLabel, predict.classLabelProbs)
     } catch {
     fatalError("can't load model")
     }*/
    
    // MARK: use Vision
    let requestHandler = VNImageRequestHandler(url: imageUrl, options: [:])
    
    do {
      try requestHandler.perform([self.recognitionSceneRequest])
    } catch {
      fatalError("can't perform VN CoreML Request")
    }
  }
}
