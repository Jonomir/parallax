import SwiftUI

struct EditorSelectionRow: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(EditorOptions.all, id: \.command) { option in
                let isSelected = selection == option.command
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selection = option.command
                    }
                } label: {
                    Text(option.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? option.tint : Color.white.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
