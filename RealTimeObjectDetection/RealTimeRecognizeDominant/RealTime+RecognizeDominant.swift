//
//  RealTime+RecognizeDominant.swift
//  RealTimeObjectDetection
//
//  Created by Harry Cao on 16/7/17.
//  Copyright © 2017 Harry Cao. All rights reserved.
//

import UIKit
import AVKit
import Vision

extension ViewController {
  
  func setupCaptureSession() {
    guard let captureSession = captureSession else { return }
    // run capture session
    captureSession.startRunning()
    
    // remove pickerImageView
    pickerImageView.removeFromSuperview()
    
    // display the capture
    previewLayer.session = captureSession
    self.view.layer.addSublayer(previewLayer)
  }
  
  func stopCaptureSession() {
    guard let captureSession = captureSession else { return }
    // stop capture session
    captureSession.stopRunning()
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if !isProcessing { return }
    
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
    /*
     // MARK: don't use Vision, but need to convert to 224x224 CVPixelBuffer
    do {
      let model = Resnet50()
      let predict = try model.prediction(image: pixelBuffer)
      print(predict.classLabel, predict.classLabelProbs)
    } catch {
      fatalError("can't load model")
    }*/
    
    // MARK: use Vision
    let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
    
    do {
      try requestHandler.perform([self.recognitionDominantRequest])
    } catch {
      fatalError("can't perform VN CoreML Request")
    }
  }
  
  @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: self.view)
    
    let panProgress = (isProcessing ? -1 : 1)*translation.x/130
    
    if !isProcessing && translation.x > 0 {
      startButton.center.x = originalButtonCenter.x + min(translation.x, 130)
    } else if isProcessing && translation.x < 0 {
      startButton.center.x = originalButtonCenter.x + max(translation.x, -130)
    } else {
      startButton.center.x = originalButtonCenter.x + translation.x
    }
    
    stopButton.alpha = isProcessing ? 0.4 : 0
    pinButton.alpha = isProcessing ? 0 : 0.4
    
    if gesture.state == .ended {
      stopButton.alpha = 0
      pinButton.alpha = 0
      
      if panProgress >= 1 {
        startButton.image = isProcessing ? nil : #imageLiteral(resourceName: "pin")
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
          self.startButton.center = self.originalButtonCenter
        }, completion: { _ in
          self.isProcessing = !self.isProcessing
        })
      }
      
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
        self.startButton.center = self.originalButtonCenter
      }, completion: nil)
    }
  }
  
  @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    if gesture.state == .began {
      isProcessing = true
      setupCaptureSession()
      
      UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2, options: .curveEaseOut, animations: {
        self.startButton.backgroundColor = UIColor(red: 60/255, green: 93/255, blue: 109/255, alpha: 1.0)
        self.startButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
      }, completion: nil)
    }
    
    if gesture.state == .ended {
      isProcessing = false
      
      UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2, options: .curveEaseOut, animations: {
        self.startButton.backgroundColor = .white
        self.startButton.transform = .identity
      }, completion: nil)
    }
  }
}
