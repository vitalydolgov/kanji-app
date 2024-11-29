import Foundation

protocol CacheServicePr {
    associatedtype Record
    associatedtype Data
    func getData(for record: Record) -> Data?
    func setData(_ data: Data, for record: Record) throws
}

protocol DataCacheServicePr: CacheServicePr where Record == Card, Data == KanjiData {

}

struct DataCacheService: DataCacheServicePr {
    func getData(for record: Card) -> KanjiData? {
        record.kanjiData
    }
    
    func setData(_ data: KanjiData, for record: Card) throws {
        record.kanjiData = data
    }
}

private extension Card {
    var kanjiData: KanjiData? {
        get {
            guard let cache = cache?.data else {
                return nil
            }
            return try? JSONDecoder().decode(KanjiData.self, from: cache)
        }
        set {
            guard let newValue, let data = try? JSONEncoder().encode(newValue),
                  let context = managedObjectContext else {
                return
            }
            let newCache = DataCache(context: context)
            newCache.data = data
            cache = newCache
        }
    }
}

