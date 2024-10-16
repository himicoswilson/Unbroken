import Foundation
import SwiftUI

@MainActor
class EntitiesViewModel: ObservableObject {
    @Published var entities: [EntityDTO] = []
    @Published var errorMessage: String?

    func fetchEntities() async {
        do {
            let fetchedEntities: [EntityDTO] = try await APIService.shared.fetch(Constants.APIEndpoints.entities)
            self.entities = fetchedEntities
            self.errorMessage = nil
        } catch let error as APIError {
            handleError(error)
        } catch {
            // 处理其他未预期的错误
            handleUnexpectedError(error)
        }
    }

    private func handleError(_ error: APIError) {
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
        print("获取实体错误: \(self.errorMessage ?? "未知错误")")
    }
    
    private func handleUnexpectedError(_ error: Error) {
        self.errorMessage = "发生未预期的错误: \(error.localizedDescription)"
        print("获取实体时发生未预期的错误: \(error)")
    }

    func updateEntityViewedStatus(_ entityID: Int) async {
        if let index = entities.firstIndex(where: { $0.entityID == entityID }) {
            entities[index].unviewed = false
        }
        let endpoint = Constants.APIEndpoints.updateLastViewed(entityID)
        do {
            try await APIService.shared.fetchWithoutResponse(endpoint)
            print("更新实体浏览状态成功")
        } catch {
            print("更新实体浏览状态失败: \(error)")
        }
    }
}
