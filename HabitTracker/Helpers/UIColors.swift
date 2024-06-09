//
//  UIColors.swift
//  HabitTracker
//
//  Created by Timofey Bulokhov on 28.04.2024.
//

import UIKit

extension UIColor {
    static var lightGrayYP: UIColor { UIColor(named: "ypLightGray")! }
    static var backgroundDay: UIColor { UIColor(named: "ypBackgroundDay")! }
    static var backgroundNight: UIColor { UIColor(named: "ypBackgroundNight")! }
    static let colorSelection: [UIColor] = [
        UIColor(named: "Color selection 1") ?? #colorLiteral(red: 1, green: 0.3956416845, blue: 0.3553284407, alpha: 1),
        UIColor(named: "Color selection 2") ?? #colorLiteral(red: 1, green: 0.606235683, blue: 0.1476774216, alpha: 1),
        UIColor(named: "Color selection 3") ?? #colorLiteral(red: 0, green: 0.5718221664, blue: 0.9856571555, alpha: 1),
        UIColor(named: "Color selection 4") ?? #colorLiteral(red: 0.5111960173, green: 0.3877502382, blue: 0.9980657697, alpha: 1),
        UIColor(named: "Color selection 5") ?? #colorLiteral(red: 0.216876775, green: 0.8317107558, blue: 0.4868133068, alpha: 1),
        UIColor(named: "Color selection 6") ?? #colorLiteral(red: 0.9293015599, green: 0.5319302678, blue: 0.8638190627, alpha: 1),
        UIColor(named: "Color selection 7") ?? #colorLiteral(red: 0.9840622544, green: 0.8660314083, blue: 0.8633159399, alpha: 1),
        UIColor(named: "Color selection 8") ?? #colorLiteral(red: 0.2413934469, green: 0.7193134427, blue: 0.9979558587, alpha: 1),
        UIColor(named: "Color selection 9") ?? #colorLiteral(red: 0.3105114102, green: 0.9077441692, blue: 0.678263247, alpha: 1),
        UIColor(named: "Color selection 10") ?? #colorLiteral(red: 0.270511806, green: 0.2811065316, blue: 0.559990108, alpha: 1),
        UIColor(named: "Color selection 11") ?? #colorLiteral(red: 1, green: 0.4940689206, blue: 0.372153759, alpha: 1),
        UIColor(named: "Color selection 12") ?? #colorLiteral(red: 1, green: 0.679395318, blue: 0.8373131156, alpha: 1),
        UIColor(named: "Color selection 13") ?? #colorLiteral(red: 0.975395143, green: 0.8091526628, blue: 0.6130551696, alpha: 1),
        UIColor(named: "Color selection 14") ?? #colorLiteral(red: 0.5460836887, green: 0.6587280631, blue: 0.9697209001, alpha: 1),
        UIColor(named: "Color selection 15") ?? #colorLiteral(red: 0.5919097066, green: 0.3043287396, blue: 0.9573236108, alpha: 1),
        UIColor(named: "Color selection 16") ?? #colorLiteral(red: 0.7400739789, green: 0.4470193386, blue: 0.8836612701, alpha: 1),
        UIColor(named: "Color selection 17") ?? #colorLiteral(red: 0.6243798137, green: 0.5432854891, blue: 0.9222726226, alpha: 1),
        UIColor(named: "Color selection 18") ?? #colorLiteral(red: 0.1919171214, green: 0.8337991834, blue: 0.4192006886, alpha: 1)
    ]
}

extension UIColor {
    static func colorComparison(colorFromSet: UIColor,trackerColor: UIColor) -> Bool {
        var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
        var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
        colorFromSet.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        trackerColor.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)
        let threshold: CGFloat = 0.01
        return abs(red1 - red2) < threshold &&
        abs(green1 - green2) < threshold &&
        abs(blue1 - blue2) < threshold &&
        abs(alpha1 - alpha2) < threshold
    }
}
