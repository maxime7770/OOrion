//
//  PatternDetection.swift
//  OOrion-Project-App
//
//  Created by Yassine Terrab on 03/03/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import CoreML
import UIKit

class PatternDetector {
    private var listPattern: [Int] = []
    
    /// Runs the model named PatternModel, found at the root of the app folder, and adds to ListPatterns the pattern name if the confidence is above the threshold
    ///
    /// - Parameter value: ImageBuffer : the UIImage on which the model will be run
    /// - Returns:
    public func RunPatternModel (ImageBuffer : UIImage) {
        let model = PatternModel()
    
        let rszdImage = resizeImage(image: ImageBuffer, newWidth: CGFloat(PatternImageSize))
        let rszdImageCVPB = rszdImage?.toCVPixelBuffer()
        
        
        let _input = PatternModelInput(input_6: rszdImageCVPB!)
        guard let PatternModelOutput = try? model.prediction(input: _input) else {
            fatalError ("Unexpected runtime error.")
        }
        
        let dict = PatternModelOutput.Identity
        
        var maxKey = -1
        var maxConf = 0.0
        
        ///Gets key corresponding to max score
        for key in dict.keys {
            if dict[key]! > maxConf && dict[key]! > ModelThres[Int(key)] {
                maxConf = dict[key]!
                maxKey = Int(key)
            }
        }

        listPattern.append(maxKey)
    }
    
    /// Returns the most frequent pattern in ListPattern
    ///
    /// - Parameter value:
    /// - Returns:a String containing the pattern name
    public func GetPattern() -> String {
        var scores = [0, 0, 0, 0, 0]
        let patternNames = ["Motif : à carreaux", "Motif : à pois", "Motif : rayé", ""]
        ///Count number of occurence per String
        for patternName in listPattern {
            switch patternName {
            case 0:
                scores[0] = scores[0] + 1
            case 1:
                scores[1] = scores[1] + 1
            case 2:
                scores[2] = scores[2] + 1
            default:
                scores[3] = scores[3] + 1
            }
        }
        let highScore = scores.max()
        listPattern = []
        if scores.firstIndex(of:highScore!) == scores.lastIndex(of:highScore!) {
            let winningPatternIndex = scores.firstIndex(of:highScore!)
            let winningPattern = patternNames[winningPatternIndex!]
            return winningPattern
        }
        else {
            return ""
        }
    }
    
    /// Resizes an image according to the input
    /// - image :  the UIImage to resize
    /// - newWidth : the width of the outpute UIImage. Its Height is computed in order to keep the ratio between Height and Width.
    /// - Returns: the resized UIImage (same type)
    
    private func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
