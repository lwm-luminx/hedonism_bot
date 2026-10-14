import Foundation

public enum DeviceCodeSignIn {
    public static func signIn(server: URL, code: String) async throws -> String {
        var request = URLRequest(url: server.appendingPathComponent("auth/device/exchange"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["code": code])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw HedonismClientError.unexpectedResponse("Could not reach the sign-in server")
        }
        guard response.statusCode == 200 else {
            throw HedonismClientError.unexpectedResponse(response.statusCode == 401
                ? "This code is invalid or expired. Ask for a new device code."
                : "Device sign-in failed. Please try again.")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["token"] as? String else {
            throw HedonismClientError.unexpectedResponse("Could not complete device sign-in")
        }
        return token
    }
}
