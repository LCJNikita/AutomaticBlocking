import Cocoa
import Foundation
import CoreBluetooth

final class MainAssembly {
    
    func assemble() -> NSViewController {
        let bluetoothScanner = BluetoothScanner()
        let presenter = MainPresenter(bluetoothScanner: bluetoothScanner)
        bluetoothScanner.delegate = presenter
        let controller = MainViewController(presenter: presenter)
        presenter.view = controller
        return controller
    }
}
