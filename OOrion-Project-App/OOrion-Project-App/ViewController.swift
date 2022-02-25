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
    @IBOutlet private weak var resultLabel: UILabel!
    @IBOutlet private weak var othersLabel: UILabel!
    @IBOutlet private weak var bbView: BoundingBoxView!
    @IBOutlet weak var cropAndScaleOptionSelector: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

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
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
        func pixelFrom(x: Int, y: Int, movieFrame: CVPixelBuffer) -> (UInt8, UInt8, UInt8) {
            CVPixelBufferLockBaseAddress(movieFrame,CVPixelBufferLockFlags(rawValue:0))
            let baseAddress = CVPixelBufferGetBaseAddress(movieFrame)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(movieFrame)
            let buffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
            CVPixelBufferUnlockBaseAddress(movieFrame,CVPixelBufferLockFlags(rawValue:0))

            let index = x*4 + y*bytesPerRow
            let b = buffer[index]
            let g = buffer[index+1]
            let r = buffer[index+2]
            
            return (r, g, b)
        }
//        let start=DispatchTime.now().uptimeNanoseconds
//        let x=pixelFrom(x: 3, y:3, movieFrame: imageBuffer)
//        let end=DispatchTime.now().uptimeNanoseconds
//        print(end-start)
//
//        var arr = [[Double]]()
//        let start2=DispatchTime.now().uptimeNanoseconds
//        for i in 0...150 {
//            for j in 0...150 {
//                let pixel=pixelFrom(x:i, y: j, movieFrame: imageBuffer)
//                arr.append([Double(pixel.0),Double(pixel.1),Double(pixel.2)])
//            }
//
//        }
//        let end2=DispatchTime.now().uptimeNanoseconds
//        print(end2-start2)
        
        func getPixels(movieFrame: CVPixelBuffer) -> [Vector] {
            CVPixelBufferLockBaseAddress(movieFrame,CVPixelBufferLockFlags(rawValue:0))
            let baseAddress = CVPixelBufferGetBaseAddress(movieFrame)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(movieFrame)
            let buffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
            CVPixelBufferUnlockBaseAddress(movieFrame,CVPixelBufferLockFlags(rawValue:0))
            var arr = [Vector]()
            for x in 0...30 {
                for y in 0...30 {
                    let index = x*4 + y*bytesPerRow
                    let b = buffer[index]
                    let g = buffer[index+1]
                    let r = buffer[index+2]
                    arr.append(Vector([Double(r),Double(g),Double(b)]))
                }
            }
            return arr
        }
        
//          let ima=UIImage(pixelBuffer: imageBuffer)
//          let ima_res=ima?.resizeImage(newWidth:150)
//        
//            let colors = try? ima_res!.dominantColors(with: .best, algorithm: .iterative)
//            //print(colors as Any)
//
//            let dominant=colors?[0].rgba
//            let r=dominant!.red * 255
//            let g=dominant!.green * 255
//            let b=dominant!.blue * 255
//            let hsv=rgbToHsv(red: r, green: g, blue:b)
//            let color=color_conversion(hsv: [hsv.h,hsv.s,hsv.v])
            //print(color)
        
//        let colors_image=ima_res?.getColors()
//        let dominant=colors_image?.background
//        let r=dominant!.red * 255
//        let g=dominant!.green * 255
//        let b=dominant!.blue * 255
//        print((r,g,b))
//        let hsv=rgbToHsv(red: r, green: g, blue:b)
//        let color=color_conversion(hsv: [hsv.h,hsv.s,hsv.v])
//        print(color)
        
//        DispatchQueue.main.async {
//            self.ColorLabel.text=color}
        
        
//        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
//        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
//        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        var arr = [[Double]]()
//        for x in 0...719 {
//            for y in 0...1279 {
//                let index = x * int32PerRow + y
//                let luma = int32Buffer[index]
//                let byteArray = withUnsafeBytes(of: luma.bigEndian) {
//                    Array($0)
//                }
//                arr.append([Double(byteArray[0]),Double(byteArray[1]),Double(byteArray[2])])
//                }
//            }
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    
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
            self.resultLabel.text = firstResult
            self.othersLabel.text = others
        })
    }

    private func updateCropAndScaleOption() {
        let selectedIndex = cropAndScaleOptionSelector.selectedSegmentIndex
        cropAndScaleOption = VNImageCropAndScaleOption(rawValue: UInt(selectedIndex))!
    }
    
    // MARK: - Actions
    
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
