import Foundation
import CoreBluetooth

struct Connection {
    let connectionId: String
    var connectionName: String?
    var rssi: Int
    let peripheral: CBPeripheral
}

protocol BluetoothScannerDelegate: AnyObject {
    
    func didFindConnection(connection: Connection)
    func didConnected()
    
    func didFailToConnect()
    func didReadRSSI(value: Int)
    func didDisconectedWithFailure()
}

final class BluetoothScanner: NSObject {
    
    weak var delegate: BluetoothScannerDelegate?
    private var centralManager: CBCentralManager!
    private var currentPeripheral: CBPeripheral?
    
    // MARK: - Init
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Properties
    private var rssiTimer: Timer?
    
    // MARK: - BluetoothScanner
    
    func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func selectConnection(of peripheral: CBPeripheral) {
        currentPeripheral = peripheral
        
        guard peripheral.state == .disconnected else { return }
        
        centralManager.connect(peripheral, options: nil)
    }
    
    func resetConnection() {
        guard let currentPeripheral = currentPeripheral else { return }
        centralManager.cancelPeripheralConnection(currentPeripheral)
    }
    
    // MARK: - Private
    
    @objc private func readRSSI() {
        currentPeripheral?.readRSSI()
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothScanner: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on")
        } else {
            print("Bluetooth is not available")
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        guard let intRSSI = RSSI as? Int, intRSSI > -50, intRSSI < 0 else { return }
        let connection = Connection(
            connectionId: peripheral.identifier.uuidString,
            connectionName: peripheral.name,
            rssi: intRSSI,
            peripheral: peripheral
        )
        delegate?.didFindConnection(connection: connection)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        peripheral.delegate = self
        centralManager.stopScan()
        delegate?.didConnected()
        
        rssiTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(readRSSI),
            userInfo: nil,
            repeats: true
        )
        peripheral.readRSSI()
        
        print("Connected to \(peripheral.identifier)")
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        delegate?.didFailToConnect()
        print("Не удалось соединиться с устройством, ошибка: \(String(describing: error))")
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        if error != nil {
            delegate?.didDisconectedWithFailure()
        }
        rssiTimer?.invalidate()
        print("Соединение с устройством потеряно, ошибка: \(String(describing: error))")
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothScanner: CBPeripheralDelegate {
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI RSSI: NSNumber,
        error: Error?
    ) {
        delegate?.didReadRSSI(value: RSSI as! Int)
        print("didReadRSSI: \(RSSI as! Int)")
    }
}
