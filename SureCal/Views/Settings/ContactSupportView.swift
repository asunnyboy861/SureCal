import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var subject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var status: SubmissionStatus?

    enum SubmissionStatus {
        case success
        case error(String)
    }

    private let subjects: [(String, String)] = [
        ("General", "bubble.left.fill"),
        ("Feature Suggestion", "lightbulb.fill"),
        ("Bug Report", "ant.fill"),
        ("Usage Question", "questionmark.circle.fill"),
        ("Performance Issue", "gauge.with.dots.needle.67percent"),
        ("UI Improvement", "paintpalette.fill"),
        ("Other", "ellipsis.circle.fill")
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") && email.contains(".") &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty &&
        (subject != "Other" || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(subjects, id: \.0) { option, icon in
                            subjectTile(option, icon: icon)
                        }
                    }
                    .padding(.vertical, 4)
                    if subject == "Other" {
                        TextField("Tell us the topic…", text: $customSubject)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("Subject")
                }

                Section {
                    TextField("Your name", text: $name)
                        .textContentType(.name)
                    TextField("yourname@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Your details")
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Tell us what's on your mind…")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .onChange(of: message) { _, newValue in
                                if newValue.count > 1000 { message = String(newValue.prefix(1000)) }
                            }
                    }
                    Text("\(message.count) / 1000")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: {
                    Text("Message")
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Submit")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || isSubmitting)
                    .listRowBackground(isValid && !isSubmitting ? Color.accentColor : Color(.systemGray4))

                    switch status {
                    case .success:
                        Label("Thank you! Your feedback has been sent.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                    case .error(let errorText):
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    case nil:
                        EmptyView()
                    }
                }
                .textCase(nil)
                .listRowBackground(Color.clear)

                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
    }

    private func subjectTile(_ title: String, icon: String) -> some View {
        let selected = subject == title
        return Button {
            subject = title
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title3)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.accentColor))
                    }
                }
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? Color.accentColor.opacity(0.16) : Color(.secondarySystemBackground))
            .foregroundStyle(selected ? Color.accentColor : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.accentColor : Color(.separator), lineWidth: selected ? 1.5 : 0.5)
            )
            .cornerRadius(10)
            .scaleEffect(selected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) subject")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func submit() {
        guard isValid else { return }
        isSubmitting = true
        status = nil
        let finalSubject = subject == "Other" ? customSubject : subject
        let payload: [String: Any] = [
            "name": name,
            "email": email,
            "subject": finalSubject,
            "message": message,
            "app_name": "SureCal"
        ]
        var request = URLRequest(url: URL(string: "https://feedback-board.iocompile67692.workers.dev/api/feedback")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error {
                    status = .error("Something went wrong: \(error.localizedDescription)")
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    status = .success
                    name = ""
                    email = ""
                    message = ""
                    customSubject = ""
                } else {
                    let serverMessage = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }?["error"] as? String
                    status = .error(serverMessage ?? "Something went wrong. Please try again.")
                }
            }
        }.resume()
    }
}
