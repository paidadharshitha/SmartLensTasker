//
//  ScannerLogic.swift
//  SmartLensTasker
//
//  Created by DHARSHITHA PAIDA on 17/01/26.
//

import SwiftUI
import VisionKit

// 1. Scanner View
struct CameraScannerView: UIViewControllerRepresentable {
    
    @Binding var scannedText: String

    func makeUIViewController(context: Context) -> DataScannerViewController {

        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator

        try? scanner.startScanning()

        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController,
                                context: Context) { }

    func makeCoordinator() -> TaskScannerCoordinator {
        TaskScannerCoordinator(parent: self)
    }
}


// 2. Coordinator Class
class TaskScannerCoordinator: NSObject, DataScannerViewControllerDelegate {

    var parent: CameraScannerView

    init(parent: CameraScannerView) {
        self.parent = parent
    }

    func dataScanner(_ dataScanner: DataScannerViewController,
                     didAdd addedItems: [RecognizedItem],
                     allItems: [RecognizedItem]) {

        for item in addedItems {

            if case .text(let textItem) = item {

                DispatchQueue.main.async {
                    self.parent.scannedText = textItem.transcript
                }

                dataScanner.stopScanning()
            }
        }
    }
}
