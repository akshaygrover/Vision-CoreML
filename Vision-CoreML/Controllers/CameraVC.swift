//
//  VideoVC.swift
//  Vision-CoreML
//
//  Created by akshay Grover on 2017-08-05.
//  Copyright © 2017 akshay Grover. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum flashState{
    case off
    case on
}

class CameraVC: UIViewController {
    
    var captureSession: AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewlayer : AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    var flashControlState: flashState = .off
    var speechSyntesizer = AVSpeechSynthesizer()

    @IBOutlet weak var captureImgView: RoundedImageView!
    @IBOutlet weak var flashBtn: RoundedShadowBtn!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewlayer.frame = cameraView.bounds
        speechSyntesizer.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.activityIndicator.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
       
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera =  AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
                
            }
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput){
                captureSession.addOutput(cameraOutput!)
                
            }
            previewlayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewlayer.videoGravity = AVLayerVideoGravity.resizeAspect
            previewlayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            
            cameraView.layer.addSublayer(previewlayer!)
            cameraView.addGestureRecognizer(tap)
            captureSession.startRunning()
            
        } catch{
            debugPrint(error)
        }
    }
    @objc func didTapCameraView() {
        
        self.cameraView.isUserInteractionEnabled = false
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        let settings = AVCapturePhotoSettings()
       // let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first!
       // let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashControlState == .off{
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?){
        
        guard let results = request.results as? [VNClassificationObservation] else { return}
        
        for classifications in results{
            if classifications.confidence < 0.4 {
                
                let unknownMessage = "I am not sure what this is. Please try again!"
                self.identificationLbl.text = unknownMessage
                synthesizeSpeech(fromString: unknownMessage)
                self.confidenceLbl.text = ""
                break
            }else{
                let identification = classifications.identifier
                let confidence = Int(classifications.confidence * 100)
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "CONFIDENCE: \(confidence)%"
                let completeSentence = "This looks like a \(identification) and I am \(confidence) percent sure"
                synthesizeSpeech(fromString: completeSentence)
                break
                
            }
        }
        
    }
    
    func synthesizeSpeech(fromString string: String){
        
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSyntesizer.speak(speechUtterance)
        
        
    }
    @IBAction func flashToggle(_ sender: RoundedShadowBtn) {
        
        switch flashControlState {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
   
        }
    }
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do{
               // let model = try VNCoreMLModel(for: SqueezeNet().model)
                let model = try VNCoreMLModel(for: Resnet50().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            }catch{
                
                debugPrint(error)
                
            }
            
            let image = UIImage(data: photoData!)
            self.captureImgView.image = image
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
        
    }
    
    
}





