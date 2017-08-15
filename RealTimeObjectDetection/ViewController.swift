//
//  ViewController.swift
//  RealTimeObjectDetection
//
//  Created by Harry Cao on 15/7/17.
//  Copyright © 2017 Harry Cao. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  var isProcessing = false
  
  let outputView: UIVisualEffectView = {
    let blurEffect = UIBlurEffect(style: .light)
    let view = UIVisualEffectView(effect: blurEffect)
    view.layer.cornerRadius = 10
    view.layer.masksToBounds = true
    view.layer.zPosition = 1
    return view
  }()
  
  let outputLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor(red: 60/255, green: 93/255, blue: 109/255, alpha: 1.0)
    label.textAlignment = .center
    label.font = UIFont(name: "Helvetica", size: 24)
    label.numberOfLines = 0
    return label
  }()
  
  var originalButtonCenter = CGPoint(x: 207, y: 668)
  lazy var startButton: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.backgroundColor = .white
    imageView.layer.cornerRadius = 40
    imageView.layer.borderColor = UIColor(red: 60/255, green: 93/255, blue: 109/255, alpha: 1.0).cgColor
    imageView.layer.borderWidth = 3
    imageView.layer.masksToBounds = true
    imageView.layer.zPosition = 1
    imageView.isUserInteractionEnabled = true
    imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openGallery)))
    imageView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePan)))
    imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress)))
    return imageView
  }()
  
  let pinButton: UIImageView = {
    let imageView = UIImageView()
    imageView.image = #imageLiteral(resourceName: "pin")
    imageView.contentMode = .scaleAspectFill
    imageView.alpha = 0
    imageView.layer.cornerRadius = 40
    imageView.layer.borderColor = UIColor(red: 60/255, green: 93/255, blue: 109/255, alpha: 1.0).cgColor
    imageView.layer.borderWidth = 3
    imageView.layer.zPosition = 1
    imageView.layer.masksToBounds = true
    return imageView
  }()
  
  let stopButton: UIImageView = {
    let imageView = UIImageView()
    imageView.image = #imageLiteral(resourceName: "stop")
    imageView.contentMode = .scaleAspectFill
    imageView.alpha = 0
    imageView.layer.cornerRadius = 40
    imageView.layer.borderWidth = 3
    imageView.layer.zPosition = 1
    imageView.layer.masksToBounds = true
    return imageView
  }()
  
  
  // MARK: Realtime Dominant Object Revognition
  lazy var previewLayer: AVCaptureVideoPreviewLayer = {
    let layer = AVCaptureVideoPreviewLayer()
    layer.frame = self.view.frame
    return layer
  }()
  
  lazy var captureSession: AVCaptureSession? = {
    // Create a capture session
    let captureSession = AVCaptureSession()
    
    // set input of the capture session
    guard
      let captureDevice = AVCaptureDevice.default(for: .video),
      let captureInput = try? AVCaptureDeviceInput(device: captureDevice)
    else {
      return nil
    }
    captureSession.addInput(captureInput)
    
    let dataOutput = AVCaptureVideoDataOutput()
    dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "objectDetection"))
    captureSession.addOutput(dataOutput)
    
    return captureSession
  }()
  
  lazy var recognitionDominantRequest: VNCoreMLRequest = {
    do {
      let model = try VNCoreMLModel(for: Resnet50().model)
      return VNCoreMLRequest(model: model, completionHandler: { (request, error) in
        guard let observations = request.results as? [VNClassificationObservation] else {
          fatalError("unexpected result type from VNCoreMLRequest")
        }
        guard let best = observations.first else {
          fatalError("can't get best result")
        }
        
        guard var name = best.identifier.components(separatedBy: ",").first else { return }
        let confidence = String(format: "%.2f", best.confidence*100) + "%"
        
        name = name == "banana" ? "banana (not 🌭)" : name
        
        DispatchQueue.main.async {
          self.outputLabel.text = name.capitalized + " • " + String(confidence)
        }
      })
    } catch {
      fatalError("can't load Vision ML model: \(error)")
    }
  }()
  
  
  // MARK: Recognize Scene
  lazy var pickerImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.backgroundColor = .white
    imageView.frame = self.view.frame
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  lazy var recognitionSceneRequest: VNCoreMLRequest = {
    do {
      let model = try VNCoreMLModel(for: GoogLeNetPlaces().model)
      return VNCoreMLRequest(model: model, completionHandler: { (request, error) in
        guard let observations = request.results as? [VNClassificationObservation] else {
          fatalError("unexpected result type from VNCoreMLRequest")
        }
        guard let best = observations.first else {
          fatalError("can't get best result")
        }
        
        guard var name = best.identifier.components(separatedBy: ",").first else { return }
        let confidence = String(format: "%.2f", best.confidence*100) + "%"
        
        DispatchQueue.main.async {
          self.outputLabel.text = name.capitalized + " • " + String(confidence)
        }
      })
    } catch {
      fatalError("can't load Vision ML model: \(error)")
    }
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    setupCaptureSession()
    setupViews()
  }
  
  func setupViews() {
    self.view.addSubview(outputView)
    outputView.contentView.addSubview(outputLabel)
    
    _ = outputView.constraintAnchorTo(top: self.view.topAnchor, topConstant: 30, bottom: nil, bottomConstant: nil, left: self.view.leftAnchor, leftConstant: 20, right: self.view.rightAnchor, rightConstant: -20)
    _ = outputView.constraintSizeToConstant(widthConstant: nil, heightConstant: 100)
    
    _ = outputLabel.constraintAnchorTo(top: outputView.topAnchor, topConstant: 0, bottom: outputView.bottomAnchor, bottomConstant: 0, left: outputView.leftAnchor, leftConstant: 0, right: outputView.rightAnchor, rightConstant: 0)
    
    self.view.addSubview(startButton)
    self.view.addSubview(stopButton)
    self.view.addSubview(pinButton)
    
    _ = startButton.constraintSizeToConstant(widthConstant: 80, heightConstant: 80)
    _ = startButton.constraintCenterTo(centerX: self.view.centerXAnchor, xConstant: 0, centerY: self.view.centerYAnchor, yConstant: 300)
    _ = stopButton.constraintSizeToConstant(widthConstant: 80, heightConstant: 80)
    _ = stopButton.constraintCenterTo(centerX: self.view.centerXAnchor, xConstant: -130, centerY: startButton.centerYAnchor, yConstant: 0)
    _ = pinButton.constraintSizeToConstant(widthConstant: 80, heightConstant: 80)
    _ = pinButton.constraintCenterTo(centerX: self.view.centerXAnchor, xConstant: 130, centerY: startButton.centerYAnchor, yConstant: 0)
  }
}

