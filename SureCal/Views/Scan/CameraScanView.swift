import SwiftUI
import AVFoundation
import SwiftData

struct CameraScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult = false
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            CameraPreview(capturedImage: $capturedImage, onCaptureError: { dismiss() })
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Close camera")
                    Spacer()
                    PhotoLibraryPicker { image in
                        if let image {
                            capturedImage = image
                            showingResult = true
                        }
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.headline)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Choose from photo library")
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
                CaptureButton { preview in
                    if let preview {
                        capturedImage = preview
                        showingResult = true
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showingResult, onDismiss: {
            capturedImage = nil
            dismiss()
        }) {
            if let image = capturedImage {
                ScanResultView(image: image)
            }
        }
    }
}

struct CaptureButton: View {
    let onCapture: (UIImage?) -> Void

    var body: some View {
        Button {
            CameraSession.shared.capture { image in
                onCapture(image)
            }
        } label: {
            ZStack {
                Circle().stroke(.white, lineWidth: 4).frame(width: 78, height: 78)
                Circle().fill(.white).frame(width: 64, height: 64)
            }
        }
        .accessibilityLabel("Take photo")
    }
}

@MainActor
final class CameraSession: NSObject, AVCapturePhotoCaptureDelegate {
    static let shared = CameraSession()
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private(set) var configured = false

    func configure() {
        guard !configured else { return }
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized ||
              AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
        } else {
            session.commitConfiguration()
            return
        }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        configured = true
        Task.detached { self.session.startRunning() }
    }

    func stop() {
        guard configured else { return }
        Task.detached { self.session.stopRunning() }
    }

    nonisolated func capture(completion: @escaping (UIImage?) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { completion(nil); return }
            Task { @MainActor in
                self.captureCompletion = completion
                self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        Task { @MainActor in
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    let onCaptureError: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        CameraSession.shared.configure()
        let layer = AVCaptureVideoPreviewLayer(session: CameraSession.shared.sessionObject)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension CameraSession {
    var sessionObject: AVCaptureSession { session }
}

struct PhotoLibraryPicker: View {
    let onImage: (UIImage?) -> Void
    let label: () -> any View

    var body: some View {
        PhotosPickerButton(onImage: onImage, label: label)
    }
}

import PhotosUI

struct PhotosPickerButton: View {
    @State private var selectedItem: PhotosPickerItem?
    let onImage: (UIImage?) -> Void
    let label: () -> any View

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            AnyView(label())
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    onImage(UIImage(data: data))
                } else {
                    onImage(nil)
                }
                selectedItem = nil
            }
        }
    }
}

func preprocessImage(_ image: UIImage) -> Data? {
    let maxDimension: CGFloat = 1024
    let scaled: UIImage
    if max(image.size.width, image.size.height) > maxDimension {
        let scale = maxDimension / max(image.size.width, image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        scaled = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    } else {
        scaled = image
    }
    return scaled.jpegData(compressionQuality: 0.75)
}
