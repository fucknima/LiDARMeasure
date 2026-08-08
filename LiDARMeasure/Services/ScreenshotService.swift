import Photos
import UIKit

enum ScreenshotError: LocalizedError {
    case unavailableView
    case imageEncodingFailed
    case photoLibraryDenied
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unavailableView: return "当前 AR 画面不可用"
        case .imageEncodingFailed: return "截图编码失败"
        case .photoLibraryDenied: return "没有照片图库写入权限"
        case .saveFailed(let error): return "保存截图失败：\(error.localizedDescription)"
        }
    }
}

@MainActor
final class ScreenshotService {
    func capture(view: UIView) -> UIImage? {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
    }

    func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ScreenshotError.photoLibraryDenied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success { continuation.resume() }
                else { continuation.resume(throwing: ScreenshotError.saveFailed(error ?? CocoaError(.fileWriteUnknown))) }
            }
        }
    }

    func saveToDocuments(_ image: UIImage, fileManager: FileManager = .default) throws -> String {
        guard let data = image.pngData() else { throw ScreenshotError.imageEncodingFailed }
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let fileURL = directory.appendingPathComponent("measurement-\(UUID().uuidString).png")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }
}

