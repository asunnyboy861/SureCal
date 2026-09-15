import SwiftUI
import AVFoundation
import SwiftData

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var lookupResult: FoodRecord?
    @State private var isLookingUp = false
    @State private var errorText: String?
    @State private var grams: Double = 100
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Group {
                if let record = lookupResult {
                    resultView(record)
                } else if isLookingUp {
                    ProgressView("Looking up product…")
                } else if let message = errorText {
                    VStack(spacing: 12) {
                        Text(message)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Scan Again") { errorText = nil }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    BarcodeScannerRepresentable(onFound: handleBarcode)
                        .overlay(alignment: .top) {
                            Text("Point at a barcode")
                                .font(.headline)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.top, 24)
                        }
                }
            }
            .navigationTitle("Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func resultView(_ record: FoodRecord) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(record.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("per 100 g: \(Int(record.kcalPer100g)) kcal · P \(Int(record.protein))g · C \(Int(record.carbs))g · F \(Int(record.fat))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Source: \(record.source)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack {
                Stepper(value: $grams, in: 10...1000, step: 10) {
                    Text("\(Int(grams)) g")
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 40)
            let nutrition = NutritionLookup.nutrition(forGrams: grams, of: record)
            Text("\(Int(nutrition.kcal)) kcal · P \(Int(nutrition.protein))g · C \(Int(nutrition.carbs))g · F \(Int(nutrition.fat))g")
                .font(.title3.bold().monospacedDigit())
            Button {
                save(record, nutrition: nutrition)
            } label: {
                Text("Add to Today")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            Spacer()
        }
        .padding(.top, 32)
    }

    private func handleBarcode(_ barcode: String) {
        guard lookupResult == nil, !isLookingUp else { return }
        isLookingUp = true
        Task {
            let record = await NutritionLookup.fetchBarcode(barcode)
            await MainActor.run {
                isLookingUp = false
                if let record {
                    lookupResult = record
                } else {
                    errorText = "Product not found in Open Food Facts. Try manual entry instead."
                }
            }
        }
    }

    private func save(_ record: FoodRecord, nutrition: (kcal: Double, protein: Double, carbs: Double, fat: Double)) {
        guard !saved else { return }
        saved = true
        let meal = MealLog(date: Date(), mealType: mealTypeForNow(), source: "barcode_off")
        let entry = FoodEntry(name: record.name, grams: grams, kcal: nutrition.kcal, protein: nutrition.protein, carbs: nutrition.carbs, fat: nutrition.fat, confidence: 1.0)
        meal.items = [entry]
        entry.meal = meal
        modelContext.insert(meal)
        try? modelContext.save()
        Task { await HealthKitWriter.shared.write(meal: meal) }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private func mealTypeForNow() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "breakfast"
        case 11..<15: return "lunch"
        case 15..<17: return "snack"
        case 17..<22: return "dinner"
        default: return "snack"
        }
    }
}

struct BarcodeScannerRepresentable: UIViewRepresentable {
    let onFound: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            DispatchQueue.main.async { onFound("") }
            return view
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        context.coordinator.session = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onFound: (String) -> Void
        var session: AVCaptureSession?

        init(onFound: @escaping (String) -> Void) {
            self.onFound = onFound
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let object = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
                  let value = object.stringValue else { return }
            session?.stopRunning()
            onFound(value)
        }
    }
}
