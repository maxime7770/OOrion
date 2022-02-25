//
//  ViewController.swift
//  CoreMLPlayground
//
//  Created by Shuichi Tsutsumi on 2018/06/14.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import VideoToolbox
import ColorKit

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}

extension UIImage {
    func resizeImage(newWidth: CGFloat) -> UIImage {

        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    } }

class ViewController: UIViewController {

    private var videoCapture: VideoCapture!
    private let serialQueue = DispatchQueue(label: "com.shu223.coremlplayground.serialqueue")
    
    private let videoSize = CGSize(width: 1280, height: 720)
    private let preferredFps: Int32 = 2
    
    private var modelUrls: [URL]!
    private var selectedVNModel: VNCoreMLModel?
    private var selectedModel: MLModel?

    private var cropAndScaleOption: VNImageCropAndScaleOption = .scaleFit
    
    @IBOutlet private weak var previewView: UIView!
    @IBOutlet weak var ColorLabel: UILabel!
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet private weak var resultView: UIView!
    @IBOutlet private weak var bbView: BoundingBoxView!
    @IBOutlet weak var cropAndScaleOptionSelector: UISegmentedControl!
    
    private var myView: UIView?
    
    public let xPos = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get screen size object.
        let screenSize: CGRect = UIScreen.main.bounds
                
        // get screen width.
        let screenWidth = screenSize.width
                
        // get screen height.
        let screenHeight = screenSize.height
            
        // the rectangle width.
        let rectWidth = Int(screenWidth) - 2 * xPos
                
        // the rectangle height.
        let rectHeight = rectWidth
        
        // the rectangle top left point y axis position.
        let yPos = (Int(screenHeight) - rectWidth)/2
            
        // Create a CGRect object which is used to render a rectangle.
        let rectFrame: CGRect = CGRect(x:CGFloat(xPos), y:CGFloat(yPos), width:CGFloat(rectWidth), height:CGFloat(rectHeight))
                
        // Create a UIView object which use above CGRect object.
        myView = UIView(frame: rectFrame)
                
        // Set UIView background color.
        myView!.layer.borderWidth = 2
        myView!.layer.borderColor = UIColor.white.cgColor
            
        // Add above UIView object as the main view's subview.
        self.view.addSubview(myView!)
        
        
        
        
        
        let spec = VideoSpec(fps: preferredFps, size: videoSize)
        let frameInterval = 1.0 / Double(preferredFps)
        
        videoCapture = VideoCapture(cameraType: .back,
                                    preferredSpec: spec,
                                    previewContainer: previewView.layer)
        videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer,sampleBuffer) in
            let delay = CACurrentMediaTime() - timestamp.seconds
            if delay > frameInterval {
                return
            }
            self.serialQueue.async {
                self.runModel(imageBuffer: imageBuffer,sampleBuffer: sampleBuffer)
            }
        }
        
        ColorLabel.text = ""
        myView!.isHidden = true
        bbView.isHidden = false
        
        let modelPaths = Bundle.main.paths(forResourcesOfType: "mlmodel", inDirectory: "models")
        
        modelUrls = []
        for modelPath in modelPaths {
            let url = URL(fileURLWithPath: modelPath)
            let compiledUrl = try! MLModel.compileModel(at: url)
            modelUrls.append(compiledUrl)
        }
        
        selectModel(url: modelUrls.first!)
        
        // scaleFill
        cropAndScaleOptionSelector.selectedSegmentIndex = 2
        updateCropAndScaleOption()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            let brightnessLevel = videoCapture.brightcheck()
            if brightnessLevel > 1000 {
                let alertBr = UIAlertController(title: "Luminosité", message: "La luminosité est faible. Voulez vous activer la lampe torche.", preferredStyle: .alert)
                alertBr.addAction(UIAlertAction(title: "Oui", style: .default, handler: {action in
                    videoCapture.toggleFlash()
                }))
                alertBr.addAction(UIAlertAction(title: "Non", style: .cancel, handler: nil))
                self.present(alertBr, animated: true)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
        // TODO: Should be dynamically determined
        self.bbView.updateSize(for: CGSize(width: videoSize.height, height: videoSize.width))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.stopCapture()
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private
    
    private func showActionSheet() {
        let alert = UIAlertController(title: "Models", message: "Choose a model", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        for modelUrl in modelUrls {
            let action = UIAlertAction(title: modelUrl.modelName, style: .default) { (action) in
                self.selectModel(url: modelUrl)
            }
            alert.addAction(action)
        }
        present(alert, animated: true, completion: nil)
    }
    
    private func selectModel(url: URL) {
        selectedModel = try! MLModel(contentsOf: url)
        do {
            selectedVNModel = try VNCoreMLModel(for: selectedModel!)
            modelLabel.text = url.modelName
        }
        catch {
            fatalError("Could not create VNCoreMLModel instance from \(url). error: \(error).")
        }
    }
    
    
    private func runModel(imageBuffer: CVPixelBuffer,sampleBuffer: CMSampleBuffer) {
        guard let model = selectedVNModel else { return }
        bbView.imageBuffer=imageBuffer
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            if let results = request.results as? [VNClassificationObservation] {
                self.processClassificationObservations(results)
            } else if #available(iOS 12.0, *), let results = request.results as? [VNRecognizedObjectObservation] {
                self.processObjectDetectionObservations(results)
            }
        })
        
        request.preferBackgroundProcessing = true
        request.imageCropAndScaleOption = cropAndScaleOption
        
        do {
            try handler.perform([request])
        } catch {
            print("failed to perform")
        }
    }
    
    
    @available(iOS 12.0, *)
    private func processObjectDetectionObservations(_ results: [VNRecognizedObjectObservation]) {
        bbView.observations = results
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.resultView.isHidden = true
            self.bbView.isHidden = false
            self.bbView.setNeedsDisplay()
            self.ColorLabel.text = ""
        }
    }

    private func processClassificationObservations(_ results: [VNClassificationObservation]) {
        var firstResult = ""
        var others = ""
        for i in 0...10 {
            guard i < results.count else { break }
            let result = results[i]
            let confidence = String(format: "%.2f", result.confidence * 100)
            if i==0 {
                firstResult = "\(result.identifier) \(confidence)"
            } else {
                others += "\(result.identifier) \(confidence)\n"
            }
        }
        DispatchQueue.main.async(execute: {
            self.bbView.isHidden = true
            self.resultView.isHidden = false
        })
    }

    private func updateCropAndScaleOption() {
        let selectedIndex = cropAndScaleOptionSelector.selectedSegmentIndex
        cropAndScaleOption = VNImageCropAndScaleOption(rawValue: UInt(selectedIndex))!
    }

    private func getColorCenter(imageBuffer: CVPixelBuffer,sampleBuffer: CMSampleBuffer) {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
    
        let rectWidth = Int(screenWidth) - 2 * xPos
        // the rectangle height.
        let rectHeight = rectWidth
        let rectH_CG = CGFloat(rectHeight)
        let rectW_CG = CGFloat(rectWidth)
    
    
        let ima=UIImage(pixelBuffer: imageBuffer)
        let cropIma = Crop(sourceImage : ima! , length : rectH_CG, width : rectW_CG)
        let cropImaUI = UIImage(cgImage: cropIma)
        let colors = try? cropImaUI.dominantColors(algorithm: .iterative)
        
        let dominant=colors?[0].rgba
        let r=dominant!.red * 255
        let g=dominant!.green * 255
        let b=dominant!.blue * 255
        let hsv=rgbToHsv(red: r, green: g, blue:b)
        let color=color_conversion(hsv: [hsv.h,hsv.s,hsv.v])
    
        
        DispatchQueue.main.async {
            self.bbView.isHidden = true
            self.ColorLabel.isHidden = false
            self.ColorLabel.text=color
        }
    }
    // MARK: - Actions
    
    @IBAction func Mode(_ sender: UIButton) {
        let alert = UIAlertController(title: "Mode", message: "Choose a mode", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let actionYolo = UIAlertAction(title: "Yolov5", style: .default) { (action) in
            self.myView!.isHidden = true
            self.bbView.isHidden = false
            self.ColorLabel.text = ""
            let frameInterval = 1.0 / Double(self.preferredFps)
            self.videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer,sampleBuffer) in
                let delay = CACurrentMediaTime() - timestamp.seconds
                if delay > frameInterval {
                    return
                }
                self.serialQueue.async {
                    self.runModel(imageBuffer: imageBuffer,sampleBuffer: sampleBuffer)
                }
            }
        }
        alert.addAction(actionYolo)
    
        let actionColor = UIAlertAction(title: "Color", style: .default) { (action) in
            self.myView!.isHidden = false
            self.bbView.isHidden = true
            let frameInterval = 1.0 / Double(self.preferredFps)
            self.videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer,sampleBuffer) in
                let delay = CACurrentMediaTime() - timestamp.seconds
                if delay > frameInterval {
                    return
                }
                
                self.serialQueue.async {
                    self.getColorCenter(imageBuffer: imageBuffer,sampleBuffer: sampleBuffer)
                }
            }
        }
        alert.addAction(actionColor)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func modelBtnTapped(_ sender: UIButton) {
        showActionSheet()
    }
    
    @IBAction func cropAndScaleOptionChanged(_ sender: UISegmentedControl) {
        updateCropAndScaleOption()
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popover" {
            let vc = segue.destination
            vc.modalPresentationStyle = UIModalPresentationStyle.popover
            vc.popoverPresentationController!.delegate = self
        }
        
        if let modelDescriptionVC = segue.destination as? ModelDescriptionViewController, let model = selectedModel {
            modelDescriptionVC.modelDescription = model.modelDescription
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension URL {
    var modelName: String {
        return lastPathComponent.replacingOccurrences(of: ".mlmodelc", with: "")
    }
}


func Crop(sourceImage : UIImage, length : CGFloat, width : CGFloat) -> CGImage {
    // The shortest side

    // Determines the x,y coordinate of a centered
    // sideLength by sideLength square
    let sourceSize = sourceImage.size
    let xOffset = (sourceSize.width - width) / 2.0
    let yOffset = (sourceSize.height - length) / 2.0

    // The cropRect is the rect of the image to keep,
    // in this case centered
    let cropRect = CGRect(
        x: xOffset,
        y: yOffset,
        width: width,
        height: length
    ).integral

    // Center crop the image
    let sourceCGImage = sourceImage.cgImage!
    let croppedCGImage = sourceCGImage.cropping(
        to: cropRect
    )!
    
    return croppedCGImage
}
