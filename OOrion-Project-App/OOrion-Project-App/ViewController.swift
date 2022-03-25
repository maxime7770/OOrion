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
    
    private let videoSize = CGSize(width: videoSizeWidth, height: videoSizeHeight)
    private let preferredFps: Int32 = 2
    
    private var modelUrls: [URL]!
    private var selectedVNModel: VNCoreMLModel?
    private var selectedModel: MLModel?
    
    @IBOutlet private weak var previewView: UIView!
    @IBOutlet weak var ColorLabel: UILabel?
    @IBOutlet weak var TextLabel: UILabel!
    @IBOutlet weak var PatternLabel: UILabel?
    @IBOutlet private weak var resultView: UIView!
    @IBOutlet private weak var bbView: BoundingBoxView!
    
    
    @IBOutlet weak var YoloLabel: UILabel!
    @IBOutlet weak var YoloColor: UILabel!
    @IBOutlet weak var YoloText: UILabel!
    
    
    private var myView: UIView?
    private var listPattern: [String] = []
    
    
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
        
        
        bbView.mode=1
        
        
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
        
        PatternLabel!.text = ""
        TextLabel?.text = ""
        ColorLabel!.text = ""
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
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
    
    
    @available(iOS 12.0, *)
    private func processObjectDetectionObservations(_ results: [VNRecognizedObjectObservation]) {
        bbView.observations = results
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.ColorLabel?.text = ""
            self.TextLabel?.text = ""
            self.PatternLabel?.text = ""
            
            self.resultView.isHidden = true
            
            self.bbView.isHidden = false
            self.bbView.setNeedsDisplay()
        }
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
    
            
        
    
    
    
    private func getColorCenter(imageBuffer: CVPixelBuffer,sampleBuffer: CMSampleBuffer) {
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
    
        let rectWidth = Int(screenWidth) - 2 * xPos
        // the rectangle height.
        let rectHeight = rectWidth
        let rectH_CG = CGFloat(rectHeight)
        let rectW_CG = CGFloat(rectWidth)
        let rectH_TextCG = CGFloat(rectHeight + 150)
        let rectW_TextCG = CGFloat(rectWidth + 150)
        
        
        let ima=UIImage(pixelBuffer: imageBuffer)
        let cropIma = Crop(sourceImage : ima! , length : rectH_CG, width : rectW_CG)
        let cropImaText = Crop(sourceImage : ima! , length : rectH_TextCG, width : rectW_TextCG)
        let cropImaUI = UIImage(cgImage: cropIma)
        
        
        
        let PatternLabel = RunPatternModel (ImageBuffer: cropImaUI)
        listPattern.append(PatternLabel)
        if listPattern.count >= 10 {
            let patternName = getPattern(listNames: listPattern)
            listPattern = []
            let colors = try? cropImaUI.dominantColorFrequencies()
            let colorText = getColorText(dominant:colors!)
            
            let detectedText = DetectText(imageToCheck: cropImaText)
            
            
            DispatchQueue.main.async {
                self.bbView.isHidden = true
                self.YoloLabel.text = ""
                self.YoloColor.text = ""
                self.YoloText.text = ""


                self.ColorLabel!.isHidden = false
                self.PatternLabel!.text = patternName
                self.ColorLabel!.text = colorText
                self.TextLabel!.text = detectedText
            }
        }
    
    func getPattern(listNames: [String]) -> String {
        var scores = [0, 0, 0, 0, 0]
        let PatternNames = ["A carreaux", "A pois", "solid", "Rayé", "nothing"]
        for patternName in listNames {
            switch patternName {
            case "A carreaux":
                scores[0] = scores[0] + 1
            case "A pois":
                scores[1] = scores[1] + 1
            case "solid":
                scores[2] = scores[2] + 1
            case "Rayé":
                scores[3] = scores[3] + 1
            default:
                scores[4] = scores[4] + 1
            }
        }
        let highScore = scores.max()
        if scores.firstIndex(of:highScore!) == scores.lastIndex(of:highScore!) {
            let winningPatternIndex = scores.firstIndex(of:highScore!)
            let winningPattern = PatternNames[winningPatternIndex!]
            return winningPattern
        }
        else {
            return "nothing"
        }
    }

    func getColorText(dominant:[ColorFrequency]) -> String {
        let dominant1=dominant[0].color.rgba
        let r1=dominant1.red * 255
        let g1=dominant1.green * 255
        let b1=dominant1.blue * 255
        let hsv1=rgbToHsv(red: r1, green: g1, blue:b1)
        let color1=color_conversion(hsv: [hsv1.h,hsv1.s,hsv1.v])
        
        if ((dominant.count) > 1) && (dominant[1].frequency) >= Col2_frequ_threshold {
            let dominant2=dominant[1].color.rgba
            let r2=dominant2.red * 255
            let g2=dominant2.green * 255
            let b2=dominant2.blue * 255
            let hsv2=rgbToHsv(red: r2, green: g2, blue: b2)
            let color2=color_conversion(hsv: [hsv2.h,hsv2.s,hsv2.v])
            
            let mainColor1 = color1.components(separatedBy: " ")[0]
            let mainColor2 = color2.components(separatedBy: " ")[0]
            if mainColor1 == mainColor2 {
                if (dominant.count) > 2 && (dominant[2].frequency) >= Col3_frequ_threshold {
                    let dominant3=dominant[2].color.rgba
                    let r3=dominant3.red * 255
                    let g3=dominant3.green * 255
                    let b3=dominant3.blue * 255
                    let hsv3=rgbToHsv(red: r3, green: g3, blue: b3)
                    let color3=color_conversion(hsv: [hsv3.h, hsv3.s, hsv3.v])
                    
                    let mainColor3 = color3.components(separatedBy: " ")[0]
                    if mainColor1 == mainColor3 {
                        return color1 + " & " + color3
                    }
                    else {
                        return color1
                    }
                }
                else {
                    return color1
                }
            }
            else {
                return color1 + " & " + color2
            }
        }
        else {
            return color1
        }
    }
    }
    // MARK: - Actions
    
    @IBAction func Mode(_ sender: UIButton) {
        let alert = UIAlertController(title: "Mode", message: "Choose a mode", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let actionYolo = UIAlertAction(title: "Yolov5", style: .default) { (action) in
            self.bbView.isHidden = false
            self.ColorLabel?.text = ""
            self.TextLabel?.text = ""
            self.PatternLabel?.text = ""
            
            self.myView!.isHidden = true
            
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
            self.bbView.isHidden = true
            self.YoloLabel.text = ""
            self.YoloColor.text = ""
            self.YoloText.text = ""

            self.myView!.isHidden = false
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


extension ViewController: UIPopoverPresentationControllerDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popover" {
            let vc = segue.destination
            vc.modalPresentationStyle = UIModalPresentationStyle.popover
            vc.popoverPresentationController!.delegate = self
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

