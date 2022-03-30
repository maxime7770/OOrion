//
//  ColorDetection.swift
//  OOrion-Project-App
//
//  Created by Alexandre Barbier on 29/03/2022.
//  Copyright © 2022 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import CoreGraphics
import ColorKit
import UIKit


class ColorDetector {
    ///Returns list of major colors from UIImage
    ///image : UIImage to check
    ///returns : Array of String of colors to display
    public func detectColor(image: UIImage) -> [String] {
        let colors = (try? image.dominantColorFrequencies())
        return self.getColorText(dominant:colors!)
    }
    
    /// Analyzes the frequencies of each color in order to return the most present one(s)
    /// - dominant : an array of ColorFrequency
    /// - Returns: a list of Strings containing the colors names
    private func getColorText(dominant:[ColorFrequency]) -> [String] {
        let dominant1=dominant[0].color.rgba
        let r1=dominant1.red * 255
        let g1=dominant1.green * 255
        let b1=dominant1.blue * 255
        let hsv1=self.rgbToHsv(red: r1, green: g1, blue:b1)
        let color1=self.colorConversion(hsv: [hsv1.h,hsv1.s,hsv1.v])
        // If the second most present color is present enough, it is also returned
        if ((dominant.count) > 1) && (dominant[1].frequency) >= Col2_frequ_threshold {
            let dominant2=dominant[1].color.rgba
            let r2=dominant2.red * 255
            let g2=dominant2.green * 255
            let b2=dominant2.blue * 255
            let hsv2=self.rgbToHsv(red: r2, green: g2, blue: b2)
            let color2=self.colorConversion(hsv: [hsv2.h,hsv2.s,hsv2.v])
            
            let mainColor1 = color1.components(separatedBy: " ")[0]
            let mainColor2 = color2.components(separatedBy: " ")[0]
            
            // If the first and second most present color are similar
            // (red and dark red for example), the third color is returned
            // if it is present enough
            
            if mainColor1 == mainColor2 {
                if (dominant.count) > 2 && (dominant[2].frequency) >= Col3_frequ_threshold {
                    let dominant3=dominant[2].color.rgba
                    let r3=dominant3.red * 255
                    let g3=dominant3.green * 255
                    let b3=dominant3.blue * 255
                    let hsv3=self.rgbToHsv(red: r3, green: g3, blue: b3)
                    let color3=self.colorConversion(hsv: [hsv3.h, hsv3.s, hsv3.v])
                    
                    let mainColor3 = color3.components(separatedBy: " ")[0]
                    if mainColor1 == mainColor3 {
                        return [color1, color3]
                    }
                    else {
                        return [color1]
                    }
                }
                else {
                    return [color1]
                }
            }
            else {
                return [color1, color2]
            }
        }
        else {
            return [color1]
        }
    }


    /// Converts a color from the RGB format to the HSV Format
    /// - Input: a tuple of 3 CGFloats corresponding to the 3 components of the RGB format
    /// - Returns : a tuple of 3 CGFloats corresponding to the 3 components of the HSV format
    
    private func rgbToHsv(red:CGFloat, green:CGFloat, blue:CGFloat) -> (h:CGFloat, s:CGFloat, v:CGFloat){
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
    
    
    
    /// Converts a color from the HSV format to its name in french
    /// - hsv : an array of 3 CGFloats containing the HSV code of the color
    /// - Returns: a String containing the color's name in french
    
    private func colorConversion (hsv : Array<CGFloat>) -> String {
        let h = hsv[0]
        let s = hsv[1] * 100
        let v = hsv[2] * 100
        // If s is too low, the color can only be Black, Grey and White
        // It depends on the v component
        switch s {
        case 0...10:
            switch v {
            case 0...30:
                return "Noir"
            case 30...75:
                return "Gris"
            default:
                return "Blanc"
            }
        // The color depends on h, but its brightness depends on v
        default:
            switch h {
            case 0...18:
                switch v {
                    case 0...10:
                        return "Noir"
                    case 10...30:
                        return "Marron"
                    case 30...60:
                        return "Rouge foncé"
                    default:
                        return "Rouge"
                }
            case 18...40:
                switch s {
                    case 0...20:
                        switch v {
                        case 0...30:
                            return "Noir"
                        case 30...75:
                            return "Gris"
                        default:
                            return "Blanc"
                        }
                    default:
                        switch v {
                        case 0...10:
                            return "Noir"
                        case 10...30:
                            return "Marron foncé"
                        case 30...60:
                            return "Marron"
                        default:
                            return "Orange"
                        }
                }
                case 40...65:
                    switch s {
                    case 0...20:
                        switch v {
                        case 0...30:
                            return "Noir"
                        case 39...75:
                            return "Gris"
                        default:
                            return "Blanc"
                        }
                    default:
                        switch v {
                        case 0...10:
                            return "Noir"
                        case 10...30:
                            return "Jaune foncé"
                        default:
                            return "Jaune"
                        }
                    }
                case 66...142:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...50:
                        return "Vert foncé"
                    case 50...80:
                        return "Vert"
                    default:
                        return "Vert clair"
                    }
                case 142...175:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...30:
                        return "Turquoise foncé"
                    default:
                        return "Turquoise"
                    }
                case 175...205:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...50:
                        return "Bleu marine"
                    case 50...80:
                        return "Bleu"
                    default:
                        return "Bleu clair"
                    }
                case 205...265:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...50:
                        return "Bleu marine"
                    case 50...70:
                        return "Bleu foncé"
                    default:
                        return "Bleu"
                    }
                case 265...295:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...50:
                        return "Violet foncé"
                    default:
                        return "Violet"
                    }
                case 295...335:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...50:
                        return "Rose foncé"
                    default:
                        return "Rose"
                    }
                case 335...360:
                    switch v {
                    case 0...10:
                        return "Noir"
                    case 10...30:
                        return "Marron"
                    case 30...60:
                        return "Rouge foncé"
                    default:
                        return "Rouge"
                    }
                default:
                    return ""
                }
            }
    }
    
}







