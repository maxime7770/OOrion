import Foundation
import CoreGraphics

func color_conversion (hsv : Array<CGFloat>) -> String {
    let h = hsv[0]
    let s = hsv[1] * 100
    let v = hsv[2] * 100
    
    if s <= 10  {
        if v <= 30 {
            return "black"
            }
        else if v <= 80 {
            return "gray"
            }
        else {
            return "white"
            }
        }
    if h <= 18 && h >= 0 {
        let res = "red"
        if v <= 10 {
            return "black"
            }
        else if  v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 40 && h >= 18 {
        let res = "orange"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 65 && h >= 40 {
        let res = "yellow"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 142 && h >= 65 {
        let res = "green"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 185 && h >= 142 {
        let res = "cyan"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 265 && h >= 185 {
        let res = "blue"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 295 && h >= 265 {
        let res = "purple"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 335 && h >= 295 {
        let res = "pink"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    if h <= 360 && h >= 335 {
        let res = "red"
        if v <= 10 {
            return "black"
            }
        else if v <= 30 {
           return "dark" + res
            }
        else {
            return res
            }
        }
    return ""
    }
