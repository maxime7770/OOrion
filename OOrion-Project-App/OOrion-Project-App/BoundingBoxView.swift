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
    var observations: [VNDetectedObjectObservation]!
    var imageBuffer: CVPixelBuffer?
    
    func updateSize(for imageSize: CGSize) {
        imageRect = AVMakeRect(aspectRatio: imageSize, insideRect: self.bounds)
    }
    
    
    
    override func draw(_ rect: CGRect) {
        guard observations != nil && observations.count > 0 else { return }
        subviews.forEach({ $0.removeFromSuperview() })

        let context = UIGraphicsGetCurrentContext()!
        let im=UIImage(pixelBuffer: imageBuffer!)?.cgImage

        let observations_copy=observations
        var color_detected = ""
        for i in 0..<observations_copy!.count {
            let observation = observations_copy![i]
            
            let color = UIColor(hue: CGFloat(i) / CGFloat(observations.count), saturation: 1, brightness: 1, alpha: 1)
            let rect = drawBoundingBox(context: context, observation: observation, color: color)
            
            //print(convertedRect)
           
            let rect_complete=CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 720, height: 1280))
                                     
                                     
            let new_width = rect.width * 2.25
            let new_height=rect.height * 2.25
            let new_x=rect.origin.x * 2.25
            let new_y=rect.origin.y * 2.25 - 140
            let new_rect=CGRect(origin: CGPoint(x: new_x, y: new_y), size: CGSize(width: new_width, height: new_height))
            //print(new_rect)
            
            if new_rect.intersects(rect_complete)==true {
            let inter_rect = new_rect.intersection(rect_complete)
            let croppedCGImage = im!.cropping(
                to: inter_rect)!
            
                                     
            
            let im_crop=UIImage(cgImage: croppedCGImage)
            //UIImageWriteToSavedPhotosAlbum(im_crop, nil, nil, nil)

            let colors_detected = try? im_crop.dominantColors(with: .fair, algorithm: .iterative)
            let dominant=colors_detected![0].rgba
            
            //print(colors_detected!)
            //print(dominant)
            let r=dominant.red * 255
            let g=dominant.green * 255
            let b=dominant.blue * 255
            //print((r,g,b))
            let hsv=rgbToHsv(red: r, green: g, blue:b)
            color_detected=color_conversion(hsv: [hsv.h,hsv.s,hsv.v])
                //print(color_detected)
            }
            
            if #available(iOS 12.0, *), let recognizedObjectObservation = observation as? VNRecognizedObjectObservation {
                addLabel(on: rect, observation: recognizedObjectObservation, color: color, color_detected: color_detected)
            }
        }
    }
            
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

    @available(iOS 12.0, *)
    private func addLabel(on rect: CGRect, observation: VNRecognizedObjectObservation, color: UIColor, color_detected: String) {
        guard let firstLabel = observation.labels.first?.identifier else { return }
                
        let label = UILabel(frame: .zero)
        label.text = color_detected + " " + firstLabel
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
