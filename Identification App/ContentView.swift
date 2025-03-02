import UIKit
import SwiftUI

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var viewModel = SimilarityViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Reference Images Section
                VStack(alignment: .leading) {
                    Text("Reference Images")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.referenceImages.indices, id: \.self) { index in
                                ReferenceImageView(image: viewModel.referenceImages[index])
                                    .frame(width: 100, height: 100)
                                    .onTapGesture {
                                        viewModel.removeReferenceImage(at: index)
                                    }
                            }
                            
                            if viewModel.referenceImages.count < 4 {
                                AddImageButton {
                                    viewModel.showReferenceImagePicker = true
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // Test Image Section
                VStack(alignment: .leading) {
                    Text("Test Image")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ZStack {
                        if let testImage = viewModel.testImage {
                            Image(uiImage: testImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    Button(action: {
                                        viewModel.removeTestImage()
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 22))
                                            .background(Circle().fill(Color.white))
                                            .padding(8)
                                    }
                                    .offset(x: 5, y: -5),
                                    alignment: .topTrailing
                                )
                        } else {
                            AddImageButton {
                                viewModel.showTestImagePicker = true
                            }
                            .frame(height: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Results Section
                if !viewModel.similarityResults.matches.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Similarity Results")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        let sortedResults = viewModel.similarityResults.matches.sorted { $0.score > $1.score }
                                
                        if let topResult = sortedResults.first {
                            Text(topResult.score > 0.9 ? "It is your Dog!" : "It is not your Dog!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(topResult.score > 0.9 ? .green : .red)
                                .padding(.horizontal)
                        }
                        
//                        ForEach(viewModel.similarityResults.matches, id: \SimilarityResult.id) { result in
//                            ResultRow(result: result)
//                                .padding(.horizontal)
//                        }
                    }
                    .padding(.vertical)
                }
                
                Spacer()
                
                // Action Buttons
                VStack {
                    Button {
                        Task {
                            await viewModel.uploadReferenceImages()
                        }
                    } label: {
                        Text("Upload Reference Images")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canUploadReferenceImages ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!viewModel.canUploadReferenceImages)
                    .padding(.horizontal)
                    
                    Button {
                        Task {
                            await viewModel.compareTestImage()
                        }
                    } label: {
                        Text("Compare Test Image")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canCompareTestImage ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!viewModel.canCompareTestImage)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Find your Dog")
            .sheet(isPresented: $viewModel.showReferenceImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedReferenceImage)
            }
            .sheet(isPresented: $viewModel.showTestImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedTestImage)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ReferenceImageView: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
            .clipped()
            .cornerRadius(8)
            .overlay(
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .background(Circle().fill(Color.white))
                    .offset(x: 5, y: -5),
                alignment: .topTrailing
            )
    }
}

struct AddImageButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "plus")
                    .font(.system(size: 30))
                Text("Add Image")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct ResultRow: View {
    let result: SimilarityResult

    var body: some View {
        HStack {
            Text("Reference: \(result.filename)")
                .font(.subheadline)

            Spacer()

            Text("Similarity: \(Int(result.score * 100))%")
                .font(.subheadline)
                .foregroundColor(scoreColor(score: result.score))
        }
        .padding(.vertical, 4)
    }
    
    private func scoreColor(score: Double) -> Color {
        if score >= 0.9 {
            return .green
        } else if score >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Processing...")
                    .foregroundColor(.white)
                    .bold()
            }
            .padding(20)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(10)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - View Model
class SimilarityViewModel: ObservableObject {
    @Published var referenceImages: [UIImage] = []
    @Published var testImage: UIImage?
    @Published var selectedReferenceImage: UIImage? {
        didSet {
            if let image = selectedReferenceImage, referenceImages.count < 4 {
                referenceImages.append(image)
                selectedReferenceImage = nil
            }
        }
    }
    @Published var selectedTestImage: UIImage? {
        didSet {
            if let image = selectedTestImage {
                testImage = image
                selectedTestImage = nil
            }
        }
    }
    @Published var showReferenceImagePicker = false
    @Published var showTestImagePicker = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var similarityResults: APIResponse = APIResponse(matches: [])
    
    var canUploadReferenceImages: Bool {
        !referenceImages.isEmpty && !isLoading
    }
    
    var canCompareTestImage: Bool {
        !referenceImages.isEmpty && testImage != nil && !isLoading
    }
    
    func removeReferenceImage(at index: Int) {
        referenceImages.remove(at: index)
    }
    
    func removeTestImage() {
        testImage = nil
        // If you're also clearing results when removing the test image:
        similarityResults = APIResponse(matches: [])
    }
    
    func uploadReferenceImages() async {
        guard !referenceImages.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Convert images to data
            let imageDataArray = referenceImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
            
            // Call API to upload reference images
            let results = try await APIService.shared.uploadReferenceImages(imageDataArray)
            
            await MainActor.run {
                isLoading = false
                // Handle successful upload (you might want to store a session ID or something)
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to upload reference images: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    func compareTestImage() async {
        guard let testImage = testImage, !referenceImages.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Convert test image to data
            guard let imageData = testImage.jpegData(compressionQuality: 0.7) else {
                throw NSError(domain: "app.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            }
            
            // Call API to compare test image with reference images
            let results = try await APIService.shared.compareTestImage(imageData)
            
            await MainActor.run {
                isLoading = false
                similarityResults = results
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to compare test image: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

