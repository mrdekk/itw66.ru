//  Created by Denis Malykh on 29.06.2023.

import Foundation

extension String {
    var russianTransliterated: String {
        self
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
            .map { String($0) }
            .map {
                if let repl = replacements[$0] {
                    return repl
                }
                return $0
            }
            .joined()
    }
}

private let replacements = [
    "а" : "a",
    "б" : "b",
    "в" : "v",
    "г" : "g",
    "д" : "d",
    "е" : "e",
    "ё" : "jo",
    "ж" : "zh",
    "з" : "z",
    "и" : "i",
    "й" : "y",
    "к" : "k",
    "л" : "l",
    "м" : "m",
    "н" : "n",
    "о" : "o",
    "п" : "p",
    "р" : "r",
    "с" : "s",
    "т" : "t",
    "у" : "u",
    "ф" : "f",
    "х" : "kh",
    "ц" : "c",
    "ч" : "ch",
    "ш" : "sh",
    "щ" : "shh",
    "ъ" : "jhh",
    "ы" : "ih",
    "ь" : "jh",
    "э" : "eh",
    "ю" : "ju",
    "я" : "ja",
    " " : "-"
]
