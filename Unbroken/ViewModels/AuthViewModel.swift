import Foundation

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    func checkAuthenticationStatus() {
        if UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.token) != nil {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    func login(username: String, password: String) {
        let loginData = ["username": username, "password": password]
        
        APIService.shared.post(Constants.APIEndpoints.login, body: loginData) { (result: Result<LoginResponse, APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    UserDefaults.standard.set(response.token, forKey: Constants.UserDefaultsKeys.token)
                    UserDefaults.standard.set(response.user.userID, forKey: Constants.UserDefaultsKeys.userID)
                    UserDefaults.standard.set(response.user.userName, forKey: Constants.UserDefaultsKeys.username)
                    self.isAuthenticated = true
                case .failure(let error):
                    // 保持原有的错误处理逻辑
                    switch error {
                    case .invalidURL:
                        self.errorMessage = "无效的URL"
                    case .noData:
                        self.errorMessage = "服务器没有返回数据"
                    case .decodingError:
                        self.errorMessage = "数据解码失败"
                    case .encodingError:
                        self.errorMessage = "数据编码失败"
                    case .networkError(let underlyingError):
                        self.errorMessage = "网络错误: \(underlyingError.localizedDescription)"
                    case .httpError(let statusCode):
                        self.errorMessage = "HTTP错误: 状态码 \(statusCode)"
                    }
                    print("登录错误: \(self.errorMessage ?? "未知错误")")
                }
            }
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.token)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.userID)
        isAuthenticated = false
    }
    
    func register(username: String, password: String, email: String) {
        let registerData = ["username": username, "password": password, "email": email]
        
        APIService.shared.post(Constants.APIEndpoints.register, body: registerData) { (result: Result<RegisterResponse, APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.isAuthenticated = true
                    UserDefaults.standard.set(response.token, forKey: Constants.UserDefaultsKeys.token)
                    UserDefaults.standard.set(response.user.userID, forKey: Constants.UserDefaultsKeys.userID)
                    UserDefaults.standard.set(response.user.userName, forKey: Constants.UserDefaultsKeys.username)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct LoginResponse: Codable {
    let token: String
    let user: User
}

struct RegisterResponse: Codable {
    let token: String
    let user: User
}