//
//  String+Extension.swift
//  LibGen
//
//  Created by Martin Stamenkovski INS on 3/24/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Foundation

extension String {
    var html: String {
        guard contains("<br") else {
            return self
        }

        let data = Data(utf8)
        if let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) {
            return attributedString.string
        }
        return self
    }
}

infix operator ?!: NilCoalescingPrecedence

public func ?! (_ str: String?, _ str2: String) -> String {
    guard let str, !str.isEmpty else {
        return str2
    }
    return str
}

public func ?! <T: Collection>(_ seq: T?, _ seq2: T) -> T {
    guard let seq, !seq.isEmpty else {
        return seq2
    }
    return seq
}

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    var isNotEmpty: Bool { !isEmpty }
}
