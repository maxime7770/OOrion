//
//  BoundingBoxView.swift
//  MLModelCamera
//
//  Created by Shuichi Tsutsumi on 2020/03/22.
//  Copyright © 2020 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Vision
import AVFoundation.AVUtilities

class BoundingBoxView: UIView {
    private let strokeWidth: CGFloat = 2
    
    private var imageRect: CGRect = CGRect.zero
    
    ///Store observations and image observed
    var observations: [VNDetectedObjectObservation]!
    var imageBuffer: CVPixelBuffer?
    
    ///Stores mode, default mode WithoutText
    enum YoloMode {
        case WithText
        case WithoutText
    }
    var mode = YoloMode.WithoutText
    
    let ColorDetect: ColorDetector = ColorDetector()
    let TextDetect: TextDetector = TextDetector()

    func updateSize(for imageSize: CGSize) {
        imageRect = AVMakeRect(aspectRatio: imageSize, insideRect: self.bounds)
    }
    
    ///Labels for moe 1 (with text)
    var Label: String = ""
    var Text: String = ""
    var Color: String = ""
    
    
    ///Draw bounding boxes (1 or 3 depending on mode (1 or 0 respectively)
    override func draw(_ rect: CGRect) {
        guard observations != nil && observations.count > 0 else { return }
        subviews.forEach({ $0.removeFromSuperview() })

        let context = UIGraphicsGetCurrentContext()!
        let im=UIImage(pixelBuffer: imageBuffer!)?.cgImage
        
        ///Limit to a maximum of 3
        let observationsCopy=observations[..<min(observations.count, 3)]

        var colorDetected = ""
        var textToDisplay = ""
        
        ///Without text mode
        switch mode {
        case .WithoutText:
            for i in 0..<observationsCopy.count {
                let observation = observationsCopy[i]
                let color = UIColor(hue: CGFloat(i) / CGFloat(observations.count), saturation: 1, brightness: 1, alpha: 1)
                let rect = drawBoundingBox(context: context, observation: observation, color: color)
                       
                let rectComplete=CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 720, height: 1280))
                
                ///Resize for color detection x2.25 to convert from User Interface units to pixels
                let newWidth = rect.width * 2.25
                let newHeight=rect.height * 2.25
                let newX=rect.origin.x * 2.25
                let newY=rect.origin.y * 2.25 - 140
                let newRect=CGRect(origin: CGPoint(x: newX, y: newY), size: CGSize(width: newWidth, height: newHeight))
            
                ///Checks if rectangle is inside screen.
                if newRect.intersects(rectComplete)==true {
                    let interRect = newRect.intersection(rectComplete)
                    let croppedCGImage = im!.cropping(
                        to: interRect)!
            
                    let imCrop=UIImage(cgImage: croppedCGImage)
            
                    let colorsDetectedList = self.ColorDetect.detectColor(image:imCrop)
                    colorDetected = colorsDetectedList[0]
                }
                
                ///Adds label
                if #available(iOS 12.0, *), let recognizedObjectObservation = observation as? VNRecognizedObjectObservation {
                    addLabel(on: rect, observation: recognizedObjectObservation, color: color, color_detected: colorDetected)
                }
            }
        ///Mode  with text
        case .WithText:
            if observationsCopy.count > 0 {
                ///Get only first observation
                let observation = observationsCopy[0]
                let color = UIColor(hue: CGFloat(0) / CGFloat(observations.count), saturation: 1, brightness: 1, alpha: 1)
                let rect = drawBoundingBox(context: context, observation: observation, color: color)
                
               
                let rectComplete=CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 720, height: 1280))
                                    
                //Color
                ///Get Color Rectangle
                let colorWidth = rect.width * 2.25
                let colorHeight=rect.height * 2.25
                let colorX=rect.origin.x * 2.25
                let colorY=rect.origin.y * 2.25 - 140
                let colorRect=CGRect(origin: CGPoint(x: colorX, y: colorY), size: CGSize(width: colorWidth, height: colorHeight))

                if colorRect.intersects(rectComplete)==true {
                    let interColorRect = colorRect.intersection(rectComplete)
                    let croppedCGImage = im!.cropping(
                        to: interColorRect)!
                    
                    let imCrop=UIImage(cgImage: croppedCGImage)
                    
                    let colorsDetectedList = self.ColorDetect.detectColor(image:imCrop)
                    colorDetected = colorsDetectedList[0]
                    
                    ///Text rectangle, slightly bigger than color rectangle, because text detection focuses on middle of rectangle given, to counter this effect, we give a bigger rectangle
                    let textRect = CGRect(origin: CGPoint(x: colorX-100, y: colorY-100), size: CGSize(width: colorWidth+200, height: colorHeight+200))
                    let interTextRect = textRect.intersection(rectComplete)
                    let croppedTextImage = im!.cropping(to: interTextRect)
                    textToDisplay = self.TextDetect.DetectText(imageToCheck: croppedTextImage!)
                }   
                let recognizedObjectObservation = observation as? VNRecognizedObjectObservation
                guard let firstLabel = recognizedObjectObservation!.labels.first?.identifier else { return }
                
                Label = toFrench[firstLabel]!
                Color = colorDetected
                Text = textToDisplay
            }

        }
    }
    
    ///Get Labels Color and Text for observation in mode 1 with text
    /// - returns : Array of String with label, color and text in this order
    public func getLabels() -> [String] {
        return [Label,Color,Text]
    }
    
    ///Returns the rectangle of BoundingBox
    ///context : CGContext in which to draw the box
    ///observation : Observation which box we want to draw
    ///color : Color of box to draw
    private func drawBoundingBox(context: CGContext, observation: VNDetectedObjectObservation, color: UIColor) -> CGRect {
        let convertedRect = VNImageRectForNormalizedRect(observation.boundingBox, Int(imageRect.width), Int(imageRect.height))
        let x = convertedRect.minX + imageRect.minX
        let y = (imageRect.height - convertedRect.maxY) + imageRect.minY
        let rect = CGRect(origin: CGPoint(x: x, y: y), size: convertedRect.size)
        context.setStrokeColor(color.cgColor)
        
        context.setLineWidth(strokeWidth)
        context.stroke(rect)
        
        return rect
    }
    
    
    ///Adds label above box drawn
    ///rect : Rectangle of the box
    ///observation : observation which is drawn
    ///color : color in which box is drawn
    ///color_detected : color detected for the object
    @available(iOS 12.0, *)
    private func addLabel(on rect: CGRect, observation: VNRecognizedObjectObservation, color: UIColor, color_detected: String) {
        guard let firstLabel = observation.labels.first?.identifier else { return }
                
        let label = UILabel(frame: .zero)
        label.text = toFrench[firstLabel]! + " " + color_detected
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: rect.origin.x-strokeWidth/2,
                             y: rect.origin.y - label.frame.height,
                             width: label.frame.width,
                             height: label.frame.height)
        addSubview(label)
    }
    
    
}
