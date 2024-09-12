import SwiftUI
import RiveRuntime

struct AnimationView: View {
    @State private var isLoaded = false
    let riveViewModel: RiveViewModel

    init() {
        riveViewModel = RiveViewModel(fileName: "paperplane")
    }

    var body: some View {
        ZStack {
            riveViewModel.view()
                .onAppear {
                    isLoaded = riveViewModel.riveFile != nil &&
                               riveViewModel.artboard != nil &&
                               riveViewModel.animation != nil
                }
            if !isLoaded {
                Text("Failed to load animation")
                    .foregroundColor(.red)
            }
        }
    }
}

