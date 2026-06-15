import Foundation

struct WordPair: Codable, Identifiable {
    var id: String { date }
    let date: String
    let wordA: String
    let wordB: String
    let wordADefinition: String?
    let wordBDefinition: String?
    let quote: String?
    let quoteAuthor: String?

    enum CodingKeys: String, CodingKey {
        case date
        case wordA = "word_a"
        case wordB = "word_b"
        case wordADefinition = "word_a_definition"
        case wordBDefinition = "word_b_definition"
        case quote
        case quoteAuthor = "quote_author"
    }
}

struct WordPairResponse: Codable {
    let date: String
    let wordA: String
    let wordB: String
    let wordADefinition: String?
    let wordBDefinition: String?
    let quote: String?
    let quoteAuthor: String?

    enum CodingKeys: String, CodingKey {
        case date
        case wordA = "word_a"
        case wordB = "word_b"
        case wordADefinition = "word_a_definition"
        case wordBDefinition = "word_b_definition"
        case quote
        case quoteAuthor = "quote_author"
    }
}

struct HistoryResponse: Codable {
    let items: [WordPairResponse]
}
