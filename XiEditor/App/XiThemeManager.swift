//
// Created by ocean on 2018/2/12.
// Copyright (c) 2018 Raph Levien. All rights reserved.
//

import Foundation

class XiThemeManager {
    public static let shared: XiThemeManager = XiThemeManager()

    public var themes: [String]?
    public var currentTheme: Theme?
}