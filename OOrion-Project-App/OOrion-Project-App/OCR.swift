////
////  OCR.swift
////  OOrion-Project-App
////
////  Created by Yassine Terrab on 14/03/2022.
////  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
////
//
//import Foundation
//import UIKit
//import Vision
//
//class OCRViewController: UIViewController {
//
//    private let label: UILabel = {
//        let label = UILabel()
//        label.numberOfLines = 0
//        label.textAlignment = .center
//        label.backgroundColor = .red
//
//        return label
//    }()
//
//    private var imageView: UIImageView  {
//        let imageView = UIImageView()
//        imageView.image = UIImage(cgImage: imageStudied)
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }
//
//    func OCRviewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(label)
//        view.addSubview(imageView)
//
//        recognizeText(image: imageView.image!)
//    }
//
//
//    func OCRviewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        imageView.frame = CGRect(
//            x: 20,
//            y: view.safeAreaInsets.top,
//            width: view.frame.size.width-40,
//            height: view.frame.size.width-40)
//        label.frame = CGRect(x:20,
//                             y: view.frame.size.width + view.safeAreaInsets.top,
//                             width: view.frame.size.width - 40,
//                             height: 200)
//
//    }
//
//
//    private func recognizeText (image : UIImage) {
//        guard let cgImage = image.cgImage else {return}
//
//    // handler
//        let handler = VNImageRequestHandler(cgImage : cgImage, options: [:])
//
//    // request
//        let request = VNRecognizeTextRequest {[weak self] request, error in
//            guard let observations = request.results as? [VNRecognizedTextObservation],
//                  error == nil else {
//                      return
//                  }
//    // Merge les textes repérés par Vision
//            let text = observations.compactMap({
//                $0.topCandidates(1).first?.string
//            }).joined(separator: ",")
//
//            DispatchQueue.main.async {
//                self?.label.text = text
//            }
//
//
//        }
//
//
//
//    // Process request
//        do {
//            try handler.perform([request])
//        }
//        catch {
//            print(error)
//        }
//
//
//
//    }
//
//}
//
//
