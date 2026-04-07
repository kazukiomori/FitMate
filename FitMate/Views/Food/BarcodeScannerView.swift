import SwiftUI
import AVFoundation

struct BarcodeScannerSheetView: View {
    let onDetected: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = BarcodeScannerViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            CameraPreview(session: scanner.captureSession)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 260, height: 160)
                        .overlay(
                            Text("バーコードを枠内に合わせてください")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.35))
                                .clipShape(Capsule())
                                .offset(y: 118)
                        )

                    if scanner.isPermissionDenied {
                        Text("カメラへのアクセスが必要です")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.7))
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            scanner.onDetected = { code in
                onDetected(code)
                dismiss()
            }
            scanner.requestAccessAndStart()
        }
        .onDisappear {
            scanner.stopSession()
        }
    }
}

final class BarcodeScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let captureSession = AVCaptureSession()

    @Published var isPermissionDenied = false

    var onDetected: ((String) -> Void)?

    private var isConfigured = false
    private var hasDetectedCode = false

    func requestAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSessionIfNeeded()
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.configureSessionIfNeeded()
                        self.startSession()
                    } else {
                        self.isPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            isPermissionDenied = true
        @unknown default:
            isPermissionDenied = true
        }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }

        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
            isConfigured = true
        }

        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            return
        }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { return }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
    }

    private func startSession() {
        hasDetectedCode = false
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetectedCode,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else {
            return
        }

        hasDetectedCode = true
        stopSession()
        onDetected?(code)
    }
}
