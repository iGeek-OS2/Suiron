
//  MemoCanvasView.swift
//  Suiron

import SwiftUI
import PencilKit

struct MemoCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawing = drawing
        canvas.delegate = context.coordinator

        let picker = context.coordinator.toolPicker
        picker.addObserver(canvas)
        picker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        coordinator.toolPicker.setVisible(false, forFirstResponder: uiView)
        uiView.resignFirstResponder()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let toolPicker = PKToolPicker()

        init(drawing: Binding<PKDrawing>) {
            self._drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}
