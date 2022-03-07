import Foundation
import CoreGraphics

func color_conversion (hsv : Array<CGFloat>) -> String {
    let h = hsv[0]
    let s = hsv[1] * 100
    let v = hsv[2] * 100
    
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







