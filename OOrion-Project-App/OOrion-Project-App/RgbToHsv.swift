//
//  RgbToHsv.swift
//  OOrion-Project-App
//
//  Created by Maxime Wolf on 23/02/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import CoreGraphics

/// Converts a color from the RGB format to the HSV Format
/// - Input: a tuple of 3 CGFloats corresponding to the 3 components of the RGB format
/// - Returns : a tuple of 3 CGFloats corresponding to the 3 components of the HSV format

func rgbToHsv(red:CGFloat, green:CGFloat, blue:CGFloat) -> (h:CGFloat, s:CGFloat, v:CGFloat){
        let r:CGFloat = red/255
        let g:CGFloat = green/255
        let b:CGFloat = blue/255
        
        let Max:CGFloat = max(r, g, b)
        let Min:CGFloat = min(r, g, b)

       //h 0-360
        var h:CGFloat = 0
        if Max == Min {
            h = 0.0
        }else if Max == r && g >= b {
            h = 60 * (g-b)/(Max-Min)
        } else if Max == r && g < b {
            h = 60 * (g-b)/(Max-Min) + 360
        } else if Max == g {
            h = 60 * (b-r)/(Max-Min) + 120
        } else if Max == b {
            h = 60 * (r-g)/(Max-Min) + 240
        }
        
       //s 0-1
        var s:CGFloat = 0
        if Max == 0 {
            s = 0
        } else {
            s = (Max - Min)/Max
        }
        
       //v
        let v:CGFloat = Max
        
        return (h, s, v)
    }
