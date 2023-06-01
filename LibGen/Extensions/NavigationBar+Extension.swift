//
//  NavigationBar+Extension.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import UIKit
extension UINavigationBar {
    func transparent() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
    }

    func removeTransparency() {
        shadowImage = nil
        setBackgroundImage(nil, for: .default)
    }
}
