import SwiftUI

struct NewPartialView: View {
    var body: some View {
        Text("New Partial Partial")
            .font(.system(size: 16))
            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            .frame(maxWidth: .infinity)
            .background(Color(red: 1.0, green: 1.0, blue: 1.0))
            .padding(16)
    }
}

// MARK: - Preview
struct NewPartialView_Previews: PreviewProvider {
    static var previews: some View {
        NewPartialView()
    }
}