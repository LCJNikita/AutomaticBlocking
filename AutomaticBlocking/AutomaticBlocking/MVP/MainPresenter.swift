import Foundation

private enum Constants {
    static let blockingRSSIValue = -74
}

final class MainPresenter {
    
    // Dependencies
    weak var view: MainViewController?
    private let bluetoothScanner: BluetoothScanner
    
    // MARK: - Init
    
    init(bluetoothScanner: BluetoothScanner) {
        self.bluetoothScanner = bluetoothScanner
    }
    
    // MARK: - MainPresenter
    
    var leftDataSource: [Connection] = []
    
    var rightDataSource: [Connection] = []
    
    func didStartScanning() {
        bluetoothScanner.startScan()
    }
    
    func didStopScanning() {
        bluetoothScanner.stopScan()
        leftDataSource = []
        view?.reloadLeft()
        rightDataSource = []
        view?.reloadRight()
    }
    
    func selectConnection(index: Int) {
        guard rightDataSource.count == 0 else { return }
        
        rightDataSource.append(leftDataSource[index])
        view?.reloadRight()
        
        bluetoothScanner.selectConnection(of: leftDataSource[index].peripheral)
    }
    
    func resetConnection() {
        rightDataSource = []
        view?.reloadRight()
        bluetoothScanner.resetConnection()
    }
    
    // MARK: - Private
    
    private func lock() {
        let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
        let sym = dlsym(libHandle, "SACLockScreenImmediate")
        typealias funcWrapper = @convention(c) () -> Void
        
        let SACLockScreenImmediate = unsafeBitCast(sym, to: funcWrapper.self)
        SACLockScreenImmediate()
    }
}

// MARK: - BluetoothScannerDelegate

extension MainPresenter: BluetoothScannerDelegate {
    
    func didFindConnection(connection: Connection) {
        
        if leftDataSource.contains(where: {
            $0.connectionId == connection.connectionId
        }) {
            let indexOfExistsElement = leftDataSource.firstIndex(where: {
                $0.connectionId == connection.connectionId
            })
            
            if let indexOfExistsElement = indexOfExistsElement {
                leftDataSource[indexOfExistsElement].connectionName = connection.connectionName
                leftDataSource[indexOfExistsElement].rssi = connection.rssi
            }
        } else {
            leftDataSource.append(connection)
        }
        
        view?.reloadLeft()
    }
    
    func didConnected() {
        leftDataSource = []
        view?.resetToStop()
        view?.reloadLeft()
    }
    
    func didFailToConnect() {
        rightDataSource = []
        view?.reloadRight()
    }
    
    func didReadRSSI(value: Int) {
        if value < Constants.blockingRSSIValue {
            resetConnection()
            lock()
            print("Вы отошли слишком далеко, блокирую экран")
        }
    }
    
    func didDisconectedWithFailure() {
        rightDataSource = []
        view?.reloadRight()
        lock()
    }
}
