import Foundation
import CoreGraphics

func color_conversion (hsv : Array<CGFloat>) -> String {
    let h = hsv[0]
    let s = hsv[1] * 100
    let v = hsv[2] * 100
    
    if s <= 10  {
        if v <= 30 {
            return "Noir"
            }
        else if v <= 75 {
            return "Gris"
            }
        else {
            return "Blanc"
            }
        }
    if h <= 18 && h >= 0 {
        let res = "Rouge"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 30 {
            return "Marron"
        }
        else if  v <= 60 {
           return res + " foncé"
            }
        else {
            return res
            }
        }
    if h <= 40 && h >= 18 {
        let res = "Orange"
        if s < 20 {
            if v <= 30 {
                return "Noir"
                }
            else if v <= 80 {
                return "Gris"
                }
            else {
                return "Blanc"
                }
            }
        else if v <= 10 {
                return "Noir"
                }
            else if v <= 30 {
                return "Marron foncé"
                }
            else if v <= 60 {
                return "Marron"
            }
            else {
                return res
                }
            }
    if h <= 65 && h >= 40 {
        let res = "Jaune"
        if s < 20 {
            if v <= 30 {
                return "Noir"
                }
            else if v <= 80 {
                return "Gris"
                }
            else {
                return "Blanc"
                }
            }
        else if v <= 10 {
                return "Noir"
                }
            else if v <= 30 {
                return res + " foncé"
                }
            else {
                return res
                }
        }
    if h <= 142 && h >= 65 {
        let res = "Vert"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 50 {
           return res + " foncé"
            }
        else if v <= 80 {
            return res
        }
        else {
            return res + " clair"
            }
        }
    if h <= 175 && h >= 142 {
        let res = "Turquoise"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 30 {
           return res + " foncé"
            }
        else {
            return res
            }
        }
    if h <= 175 && h >= 205 {
        let res = "Bleu"
        if v <= 10 {
            return "Noir"
        }
        else if v <= 50 {
            return res + " marine"
        }
        else if v <= 80 {
            return res
        }
        else {
            return res + " clair"
        }
    }
    if h <= 265 && h >= 205 {
        let res = "Bleu"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 50 {
           return res + " marine"
            }
        else if v <= 70 {
            return res + " foncé"
        }
        else {
            return res
            }
        }
    if h <= 295 && h >= 265 {
        let res = "Violet"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 50 {
           return res + " foncé"
            }
        else {
            return res
            }
        }
    if h <= 335 && h >= 295 {
        let res = "Rose"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 50 {
           return res + " foncé"
            }
        else {
            return res
            }
        }
    if h <= 360 && h >= 335 {
        let res = "Rouge"
        if v <= 10 {
            return "Noir"
            }
        else if v <= 30 {
            return "Marron"
        }
        else if  v <= 60 {
           return res + " foncé"
            }
        else {
            return res
            }
        }
    return ""
    }
