//
//  TextDetection.swift
//  OOrion-Project-App
//
//  Created by Alexandre Barbier on 25/03/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import Vision
import UIKit

var textDetected = ""

/// The handler function of the text detectoni function (it means it's called by that function)
/// - Returns: the text detected by the handler

func handleDetectedText(request: VNRequest?, error: Error?) {
    if let error = error {
        print("ERROR: \(error)")
        return
    }
    guard let results = request?.results as? [VNRecognizedTextObservation], results.count > 0 else {
        textDetected = ""
        return
    }
    
    let _: [String] = results.compactMap { (observation)  in
        guard let topCandidate = observation.topCandidates(1).first else { return nil }
        if observation.confidence == 1 {
            var allWords = ""
            let str = topCandidate.string
            let strArr = str.components(separatedBy: " ")
            // Every word will go through a text check in
            // order to correct it if it was spelled wrong
            for word in strArr {
                let textChecker = UITextChecker()
                let misspelledRange =
                    textChecker.rangeOfMisspelledWord(in: String(word),
                                                      range: NSRange(0..<String(word).utf16.count),
                                                      startingAt: 0,
                                                      wrap: false,
                                                      language: "fr_FR")

                if misspelledRange.location != NSNotFound {
                    let firstGuess = textChecker.guesses(forWordRange: misspelledRange,
                                                         in: String(word),
                                                         language: "fr_FR")?.first
                    
                    let res = firstGuess ?? ""
                    allWords.append(" " + res)
                }
                
                else {
                    allWords.append(" " + String(word))
                }
            }
            // Contains the concatenation of all the corrected words
            textDetected = allWords

        }
        
        return (textDetected)
    }
}

/// Detects the text on an image
/// - imageToCheck: the CGImage to check
/// - Returns: a String containing the text detected

func DetectText(imageToCheck: CGImage) ->  String {
    
    
    let request = VNRecognizeTextRequest(completionHandler: handleDetectedText)
    request.recognitionLevel = .fast
    request.recognitionLanguages = ["en_GB", "fr_FR"]
    
    let requests = [request]
    let imageRequestHandler = VNImageRequestHandler(cgImage: imageToCheck, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try imageRequestHandler.perform(requests)
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    return textDetected
}
