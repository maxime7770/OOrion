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

class ViewController: UIViewController {

    ///Specs to initialize ViedeoCapture Object
    private var videoCapture: VideoCapture!
    private let serialQueue = DispatchQueue(label: "com.shu223.coremlplayground.serialqueue")
    
    private let videoSize = CGSize(width: videoSizeWidth, height: videoSizeHeight)
    private let preferredFps: Int32 = 2
    
    ///Variables used to save the model used
    private var selectedVNModel: VNCoreMLModel?
    private var selectedModel: MLModel?
    
    ///Variable used to count the number of image since last refresh,
    var imageCount: Int = 0
    
    ///All Views
    @IBOutlet private weak var previewView: UIView!
    
    ///For Color Mode
    private var squareView: UIView?
    @IBOutlet weak var ColorLabel: UILabel?
    @IBOutlet weak var TextLabel: UILabel!
    @IBOutlet weak var PatternLabel: UILabel?
    
    ///For Yolo Mode
    @IBOutlet private weak var bbView: BoundingBoxView!
    ///Specifically for YoloWithText Mode
    @IBOutlet weak var YoloLabel: UILabel!
    @IBOutlet weak var YoloColor: UILabel!
    @IBOutlet weak var YoloText: UILabel!
    
    ///Function will run when ViewController is Loaded, initializes VideoCapture object and Model
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
        squareView = UIView(frame: rectFrame)
                
        // Set UIView background color.
        squareView!.layer.borderWidth = 2
        squareView!.layer.borderColor = UIColor.white.cgColor
            
        // Add above UIView object as the main view's subview.
        self.view.addSubview(squareView!)
        
                
        
        let spec = VideoSpec(fps: preferredFps, size: videoSize)
        let frameInterval = 1.0 / Double(preferredFps)
        
        videoCapture = VideoCapture(cameraType: .back,
                                    preferredSpec: spec,
                                    previewContainer: previewView.layer)
        videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer) in
            let delay = CACurrentMediaTime() - timestamp.seconds
            if delay > frameInterval {
                return
            }
            self.serialQueue.async {
                self.runModel(imageBuffer: imageBuffer)
            }
        }
        
        ///Hide and siplay what's needed to initialize in Yolov5 without text
        
        PatternLabel!.text = ""
        TextLabel?.text = ""
        ColorLabel!.text = ""
        squareView!.isHidden = true
        
        bbView.isHidden = false
        
        ///Initialize Model
        
        let modelPaths = Bundle.main.paths(forResourcesOfType: "mlmodel", inDirectory: "models")
        
        var modelUrls: [URL]!
        modelUrls = []
        for modelPath in modelPaths {
            let url = URL(fileURLWithPath: modelPath)
            let compiledUrl = try! MLModel.compileModel(at: url)
            modelUrls.append(compiledUrl)
        }
        
        selectedModel = try! MLModel(contentsOf: modelUrls.first!)
        do {
            selectedVNModel = try VNCoreMLModel(for: selectedModel!)
        }
        catch {
            fatalError("Could not create VNCoreMLModel instance from \(modelUrls.first!). error: \(error).")
        }
    }
    
    ///Function launched when ViewController will appears, starts VideoCapture, and checks brighness
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
        
        ///Checks brightness after a slight delay to give time for the View to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            let brightnessLevel = Double(videoCapture.brightcheck())
            if brightnessLevel >= brightnessLevelTreshold {
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
    
    ///Run Selected Model:
    ///
    /// - imageBuffer  : a CVPixelBuffer on which model will be run
    private func runModel(imageBuffer: CVPixelBuffer) {
        guard let model = selectedVNModel else { return }
        bbView.imageBuffer=imageBuffer
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            if #available(iOS 12.0, *), let results = request.results as? [VNRecognizedObjectObservation] {
                self.processObjectDetectionObservations(results)
            }
        })

        request.preferBackgroundProcessing = true
        request.imageCropAndScaleOption = .scaleFit

        do {
            try handler.perform([request])
        } catch {
            print("failed to perform")
        }
    }
    
    ///Displays the request results
    ///
    /// - results : Array of VNRecognizedObjectObservation corresponding to outputs of yolov5 model
    @available(iOS 12.0, *)
    private func processObjectDetectionObservations(_ results: [VNRecognizedObjectObservation]) {
        bbView.observations = results
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            ///Hides unnecessary labels
            self.ColorLabel?.text = ""
            self.TextLabel?.text = ""
            self.PatternLabel?.text = ""
            
            ///Makes sure that bbView is displayed, needed because asynchronous check of datas on images, so sometimes, mode will be changed, but next results will be displayed after the mode has been changed, and thus unhide/hide wrong elements
            self.bbView.isHidden = false
            self.bbView.setNeedsDisplay()
        }
        ///Hides or display labels whether text mode is enabled (1) or not (0)
        if bbView.mode == 1 {
            let toDisplay = bbView.getLabels()
            DispatchQueue.main.async {
                self.YoloLabel.text = "Label : " + toDisplay[0]
                self.YoloColor.text = "Couleur : " + toDisplay[1]
                self.YoloText.text = "Texte : " + toDisplay[2]
            }
        }
        else {
            DispatchQueue.main.async {
                self.YoloLabel.text = ""
                self.YoloColor.text = ""
                self.YoloText.text = ""
            }
        }
    }    
    
            
        
    /// Displays the color, the pattern and the text present on the input image
    /// - imageBuffer: the CVPixelBuffer
    /// - Returns: nil
    
    private func noObjectDetect(imageBuffer: CVPixelBuffer) {
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        
        // The rectangle of observation is created
        let rectWidth = Int(screenWidth) - 2 * xPos
        // the rectangle height.
        let rectHeight = rectWidth
        let rectH_CG = CGFloat(rectHeight)
        let rectW_CG = CGFloat(rectWidth)

        
        // The image is converted and cropped to the rectanle's size
        let ima=UIImage(pixelBuffer: imageBuffer)
        let cropIma = Crop(sourceImage : ima! , length : rectH_CG, width : rectW_CG)
        let cropImaUI = UIImage(cgImage: cropIma)
        
        ///Save output of PatternModel
        RunPatternModel (ImageBuffer: cropImaUI)
        
        ///Refresh display one in ten frames
        self.imageCount = self.imageCount + 1
        if self.imageCount >= 10 {
            ///get most frequent output of PatternModel for last 10 frames
            let detectedPattern = GetPattern()

            ///Get ColorText to Display
            var detectedColor = ""
            let detectedColorList = detectColor(image:cropImaUI)
            if detectedColorList.count == 1 {
                detectedColor = detectedColorList[0]
            }
            else if detectedColorList.count == 2 {
                detectedColor = detectedColorList[0] + " & " + detectedColorList[1]
            }
            
            
            let rectH_TextCG = CGFloat(rectHeight + 150)
            let rectW_TextCG = CGFloat(rectWidth + 150)
            let cropImaText = Crop(sourceImage : ima! , length : rectH_TextCG, width : rectW_TextCG)
            let detectedText = DetectText(imageToCheck: cropImaText)
            
            
            DispatchQueue.main.async {
                ///hides unneeded elements
                self.bbView.isHidden = true
                self.YoloLabel.text = ""
                self.YoloColor.text = ""
                self.YoloText.text = ""


                self.ColorLabel!.isHidden = false
                self.PatternLabel!.text = detectedPattern
                self.ColorLabel!.text = detectedColor
                self.TextLabel!.text = detectedText
            }
        }
    }

    // MARK: - Actions
    
    ///Change Mode button
    @IBAction func Mode(_ sender: UIButton) {
        let alert = UIAlertController(title: "Mode", message: "Choose a mode", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        ///Action corresponding to Yolo without text
        let actionYoloMode0 = UIAlertAction(title: "Yolov5 Sans Texte", style: .default) { (action) in
            self.bbView.isHidden = false
            self.ColorLabel?.text = ""
            self.TextLabel?.text = ""
            self.PatternLabel?.text = ""
            
            self.bbView.mode=0
            
            self.squareView!.isHidden = true
            
            let frameInterval = 1.0 / Double(self.preferredFps)
            self.videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer) in
                let delay = CACurrentMediaTime() - timestamp.seconds
                if delay > frameInterval {
                    return
                }
                self.serialQueue.async {
                    self.runModel(imageBuffer: imageBuffer)
                }
            }
        }
        alert.addAction(actionYoloMode0)
        
        ///Action corresponding to Yolo With Text
        let actionYoloMode1 = UIAlertAction(title: "Yolov5 Avec Texte", style: .default) { (action) in
            self.bbView.isHidden = false
            self.ColorLabel?.text = ""
            self.TextLabel?.text = ""
            self.PatternLabel?.text = ""
            
            self.bbView.mode=1
            
            self.squareView!.isHidden = true
            
            let frameInterval = 1.0 / Double(self.preferredFps)
            self.videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer) in
                let delay = CACurrentMediaTime() - timestamp.seconds
                if delay > frameInterval {
                    return
                }
                self.serialQueue.async {
                    self.runModel(imageBuffer: imageBuffer)
                }
            }
        }
        alert.addAction(actionYoloMode1)
        
        ///Action corresponding to No Object Mode
        let actionNoObject = UIAlertAction(title: "No Object", style: .default) { (action) in
            self.bbView.isHidden = true
            self.YoloLabel.text = ""
            self.YoloColor.text = ""
            self.YoloText.text = ""

            self.squareView!.isHidden = false
            let frameInterval = 1.0 / Double(self.preferredFps)
            self.videoCapture.imageBufferHandler = {[unowned self] (imageBuffer, timestamp, outputBuffer) in
                let delay = CACurrentMediaTime() - timestamp.seconds
                if delay > frameInterval {
                    return
                }
                
                self.serialQueue.async {
                    self.noObjectDetect(imageBuffer: imageBuffer)

                }
            }
        }
        alert.addAction(actionNoObject)
        
        present(alert, animated: true, completion: nil)
    }
    
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}


extension URL {
    var modelName: String {
        return lastPathComponent.replacingOccurrences(of: ".mlmodelc", with: "")
    }
}


/// Center crops a rectangle shape from an image
/// - sourceImage : original UIImage to be cropped
/// - length and width : CGFloats indicating the length and the width of the rectangular final image
/// - Returns: the cropped CGImage

func Crop(sourceImage : UIImage, length : CGFloat, width : CGFloat) -> CGImage {
    /// the position of the center of the rectangle is determined by
    /// xOffset and yOffset, which are computed in order to have a centered rectangle
    
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
