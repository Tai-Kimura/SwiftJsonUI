import SwiftUI

struct TestCorrectAttrsView: View {
    var body: some View {
        Text("Test Correct Attrs Partial")
            .font(.system(size: 16))
            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            .frame(maxWidth: .infinity)
            .background(Color(red: 1.0, green: 1.0, blue: 1.0))
            .padding(16)
    }
}

// MARK: - Preview
struct TestCorrectAttrsView_Previews: PreviewProvider {
    static var previews: some View {
        TestCorrectAttrsView()
    }
}