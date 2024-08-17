//
//  BaiduTranslator.swift
//  Polyglot
//
//  Created by Ho on 8/18/24.
//  Copyright © 2024 Sola. All rights reserved.
//

import Foundation
import Alamofire

struct BaiduTranslator {
    
    var srcLang: LangCode
    var trgLang: LangCode
    
    init(srcLang: LangCode, trgLang: LangCode) {
        self.srcLang = srcLang
        self.trgLang = trgLang
    }
    
    private func constructUrl(from query: String) -> URL? {
        
        // https://blog.csdn.net/Asphalt_9/article/details/122354967
        
        var queryItems = BaiduTranslator.queryItems
        queryItems["q"] = query
        queryItems["from"] = srcLang.baiduTranslateLangCode
        queryItems["to"] = trgLang.baiduTranslateLangCode
        queryItems["salt"] = String((0..<16).map({ _ in  // https://stackoverflow.com/questions/60634806/how-to-create-15-digit-length-random-string-in-swift
            "0123456789".randomElement()!
        }))
        queryItems["sign"] = "\(queryItems["appid"]!)\(queryItems["q"]!)\(queryItems["salt"]!)\(BaiduTranslator.key)".md5

        var components = URLComponents()
        components.scheme = BaiduTranslator.scheme
        components.host = BaiduTranslator.host
        components.path = BaiduTranslator.path
        components.queryItems = queryItems.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        return components.url
    }

    func translate(query: String, completion: @escaping ([String]) -> Void) {
        
        guard !query.strip().isEmpty else {
            completion([query])
            return
        }
        
        guard let url = constructUrl(from: query) else {
            return
        }
        
        AF.request(
            url,
            method: .post
        ).response { response in
            guard let data = response.data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let transResult = json["trans_result"] as? [[String: String]],
                    transResult.count != 0 else {
                completion([])
                return
            }
            completion(transResult.compactMap { d in
                d["dst"]
            })
        }
    }
}

extension BaiduTranslator {
    
    static private let scheme = "https"
    static private let host = "fanyi-api.baidu.com"
    static private let path = "/api/trans/vip/translate"
    static private let queryItems: [String: String] = [
        "q": "",
        "from": "",
        "to": "",
        "appid": "20240817002125900",
        "salt": "",
        "sign": "",
    ]
    static private let key: String = "MUXMCSfOSs2s39DAZ1x5"
    
}
