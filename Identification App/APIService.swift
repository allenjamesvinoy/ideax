//
//  APIService.swift
//  Identification App
//
//  Created by Allen James Vinoy on 26/02/25.
//  Copyright © 2025 TestAllen. All rights reserved.
//

import Foundation

struct APIResponse: Decodable {
    let matches: [SimilarityResult]
}

//// MARK: - Model Objects
//struct SimilarityResult: Identifiable, Decodable {
//    let id: Int
//    let score: Double
//}
struct SimilarityResult: Identifiable, Decodable {
    let id: UUID = UUID() // Unique ID for SwiftUI
    let filename: String
    let score: Double

    // Custom decoder to map array structure to properties
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        filename = try container.decode(String.self)
        score = try container.decode(Double.self)
    }
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://test-api-dis-docker-a88db0a1cb01.herokuapp.com"
    private var sessionId: String?
    
    private init() {}
    
    func uploadReferenceImages(_ imageDataArray: [Data]) async throws -> Bool {
        // Create a multipart form data request
        let url = URL(string: "\(baseURL)/extract-features/batch")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add user_id to the request (if needed)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("user123\r\n".data(using: .utf8)!) // Replace with actual user ID or app-generated ID
        
        // Add request_id to the request (optional)
        let requestId = UUID().uuidString
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"request_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(requestId)\r\n".data(using: .utf8)!)
        
        // Add each image to the request using the 'files' parameter name for all images
        for (index, imageData) in imageDataArray.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "api.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server returned an error"])
        }
        
        // Store the request_id for later use in the comparison request
        self.sessionId = requestId
        return true
    }
    
    func compareTestImage(_ imageData: Data) async throws -> APIResponse {
        guard let sessionId = sessionId else {
            throw NSError(domain: "api.error", code: 3, userInfo: [NSLocalizedDescriptionKey: "No active session. Please upload reference images first."])
        }
        
        // Create a multipart form data request
        let url = URL(string: "\(baseURL)/identify_dog")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add user_id to the request (should match what was used in uploadReferenceImages)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("user123\r\n".data(using: .utf8)!) // Replace with actual user ID or app-generated ID
        
        // Add top_k parameter (default value from your API is 5)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"top_k\"\r\n\r\n".data(using: .utf8)!)
        body.append("5\r\n".data(using: .utf8)!)
        
        // Add test image to the request
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"test.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "api.error", code: 4, userInfo: [NSLocalizedDescriptionKey: "Server returned an error"])
        }
        
        // Parse the response to get similarity results
        // This will need to be adjusted based on your API's actual response format
        let similarityResults = try JSONDecoder().decode(APIResponse.self, from: data)
        return similarityResults
    }
}
