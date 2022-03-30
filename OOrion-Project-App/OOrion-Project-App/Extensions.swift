//
//  Extensions.swift
//  OOrion-Project-App
//
//  Created by Alexandre Barbier on 30/03/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import VideoToolbox

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
    
    /// Center crops a rectangle shape from UIImage
    /// - length and width : CGFloats indicating the length and the width of the rectangular final image
    /// - Returns: the cropped CGImage
    func Crop(length : CGFloat, width : CGFloat) -> CGImage {
        /// the position of the center of the rectangle is determined by
        /// xOffset and yOffset, which are computed in order to have a centered rectangle
        
        let sourceSize = self.size
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
        let sourceCGImage = self.cgImage!
        let croppedCGImage = sourceCGImage.cropping(
            to: cropRect
        )!
        
        return croppedCGImage
    }
}
