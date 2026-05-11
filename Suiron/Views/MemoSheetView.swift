
//  MemoSheetView.swift
//  Suiron

import SwiftUI
import PencilKit

struct MemoSheetView: View {
    @Binding var drawing: PKDrawing
    var body: some View {
        ZStack(alignment: .topTrailing) {
            MemoCanvasView(drawing: $drawing)
                .background(Color(UIColor.systemBackground))

            Button {
                drawing = PKDrawing()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }
}
