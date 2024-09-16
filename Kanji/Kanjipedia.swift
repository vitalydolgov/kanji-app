import Foundation
import Alamofire
import SwiftSoup

protocol KanjiDataProviderPr {
    func getKanjiData(for kanji: Kanji) async throws -> KanjiData
}

struct KanjipediaService: KanjiDataProviderPr {
    private let baseUrl = URL(string: "https://www.kanjipedia.jp")!
    private let requestQueue = DispatchQueue(label: "request", qos: .userInitiated)
    
    func getKanjiData(for kanji: Kanji) async throws -> KanjiData {
        let task = Task {
            let html = try await getRawHtml(for: kanji)
            return try extractKanjiData(from: html)
        }
        let wait = Task {
            try await Task.sleep(for: .seconds(10))
            task.cancel()
        }
        defer { wait.cancel() }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            
        }
    }
    
    // MARK: get raw HTML
    
    private func getRawHtml(for kanji: Kanji) async throws -> String {
        let url = searchUrl(for: kanji)
        let data: Data = try await withCheckedThrowingContinuation { k in
            AF.request(url).response(queue: requestQueue) { response in
                guard response.error == nil, let data = response.data else {
                    k.resume(throwing: Exception.invalidResponse)
                    return
                }
                k.resume(returning: data)
            }
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw Exception.invalidData
        }
        return html
    }
    
    private func searchUrl(for kanji: Kanji) -> URL {
        let url = baseUrl.appending(path: "search")
        let queryItems = [
            URLQueryItem(name: "k", value: String(kanji.value)),
            URLQueryItem(name: "kt", value: "1"),
            URLQueryItem(name: "sk", value: "leftHand"),
        ]
        return url.appending(queryItems: queryItems)
    }
    
    // MARK: extract kanji data
    
    private func extractKanjiData(from html: String) throws -> KanjiData {
        let doc = try parse(html)
        guard let html = try doc.body()?.getElementById("resultKanjiList") else {
            throw Exception.invalidData
        }
        let kanji = try extractKanji(from: html)
        let yomi = try extractYomi(from: html)
        return KanjiData(kanji: kanji, yomi: yomi)
    }
    
    private func extractKanji(from html: Element) throws -> Kanji {
        guard let part = try html.getElementsByTag("li").first(),
              let char = try part.getElementsByTag("a").first()?.text().first,
              let kanji = Kanji(char) else {
            throw Exception.invalidData
        }
        return kanji
    }
    
    private func extractYomi(from elem: Element) throws -> [Yomi] {
        let allYomiElems = try elem.getElementsByClass("onkunYomi")
        let separator = try Regex("\u{30FB}|\\s+")
        var results = [Yomi]()
        for elem in allYomiElems {
            let type = try getYomiType(for: elem)
            removeAdvancedYomi(in: elem)
            let yomiParts = try elem.text().split(separator: separator)
            for part in yomiParts {
                results.append(Yomi(type: type, value: String(part)))
            }
        }
        return results
    }
    
    private func removeAdvancedYomi(in elem: Element) {
        try? elem.getElementsByAttributeValue("style", "color:#000000").first()?.replaceWith(Node())
    }
    
    private func getYomiType(for elem: Element) throws -> Yomi.YomiType {
        guard let parentElem = elem.parent() else {
            throw Exception.invalidData
        }
        let hasElement = { char in
            guard let elem = try? parentElem.getElementsByAttributeValue("alt", char) else {
                return false
            }
            return !elem.isEmpty()
        }
        if hasElement("\u{97F3}") {
            return .on
        } else if hasElement("\u{8A13}") {
            return .kun
        } else {
            throw Exception.invalidData
        }
    }
}
