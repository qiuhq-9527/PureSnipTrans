import Foundation

struct DeepLTranslation: Codable {
    let translations: [Translation]
}

struct Translation: Codable {
    let detectedSourceLanguage: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case detectedSourceLanguage = "detected_source_language"
        case text
    }
}

struct DeepLErrorResponse: Codable {
    let message: String
}

enum DeepLTranslationError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case unknownError
}

class DeepLTranslationAPI {
    private let apiKey = "填入Deepl的APIKEY"
    private let baseURL = "https://api-free.deepl.com/v2/translate"
    
    func translateTexts(_ texts: [String], sourceLanguage: String = "EN", targetLanguage: String = "ZH", completion: @escaping (Result<DeepLTranslation, DeepLTranslationError>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "text": texts,
            "source_lang": sourceLanguage,
            "target_lang": targetLanguage
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknownError))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data, let errorResponse = try? JSONDecoder().decode(DeepLErrorResponse.self, from: data) {
                    completion(.failure(.apiError(errorResponse.message)))
                } else {
                    completion(.failure(.apiError("HTTP状态码: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknownError))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(DeepLTranslation.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}
