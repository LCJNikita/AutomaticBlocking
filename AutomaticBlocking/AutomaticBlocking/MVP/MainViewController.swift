import Cocoa

final class MainViewController: NSViewController {
    
    enum TableViewType {
        case leftSide
        case rightSide
    }
    
    // Dependencies
    private let presenter: MainPresenter
    
    // UI
    private lazy var leftTableView = createTableView(type: .leftSide)
    private lazy var rightTableView = createTableView(type: .rightSide)
    private lazy var progressIndicator: NSProgressIndicator = {
        let progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isIndeterminate = true
        progressIndicator.isHidden = true
        return progressIndicator
    }()
    private lazy var startStopButton = NSButton(
        title: "Start",
        target: self,
        action: #selector(startStopButtonAction)
    )
    private lazy var resetButton = NSButton(
        title: "Reset",
        target: self,
        action: #selector(resetButtonAction)
    )
    
    private var isRunning: Bool = false
    
    // MARK: - Init
    
    init(presenter: MainPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - loadView
    
    override func loadView() {
        view = NSView(frame: NSMakeRect(0.0, 0.0, 300, 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        let leftScrollView = createScrollView(for: leftTableView)
        view.addSubview(leftScrollView)

        let rightScrollView = createScrollView(for: rightTableView)
        view.addSubview(rightScrollView)

        leftScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        leftScrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        leftScrollView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true

        rightScrollView.leadingAnchor.constraint(equalTo: leftScrollView.trailingAnchor).isActive = true
        rightScrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        rightScrollView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        
        view.addSubview(startStopButton)
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        startStopButton.centerXAnchor.constraint(
            equalTo: leftScrollView.centerXAnchor
        ).isActive = true
        startStopButton.topAnchor.constraint(
            equalTo: leftScrollView.bottomAnchor,
            constant: 10
        ).isActive = true
        startStopButton.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -10
        ).isActive = true
        
        view.addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
        progressIndicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        progressIndicator.centerYAnchor.constraint(
            equalTo: startStopButton.centerYAnchor
        ).isActive = true
        progressIndicator.trailingAnchor.constraint(
            equalTo: startStopButton.trailingAnchor,
            constant: 15
        ).isActive = true
        progressIndicator.startAnimation(nil)
        
        view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.centerXAnchor.constraint(
            equalTo: rightScrollView.centerXAnchor
        ).isActive = true
        resetButton.topAnchor.constraint(
            equalTo: rightScrollView.bottomAnchor,
            constant: 10
        ).isActive = true
        resetButton.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -10
        ).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        leftTableView.dataSource = self
        leftTableView.delegate = self

        rightTableView.dataSource = self
        rightTableView.delegate = self
    }
    
    // MARK: - Private
    
    private func createTableView(type: TableViewType) -> NSTableView {
        let tableView = NSTableView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        let columnTitle: String = {
            switch type {
            case .leftSide:
                return "Available connections"
            case .rightSide:
                return "Monitored conncetions"
            }
        }()
        column.title = columnTitle
        tableView.addTableColumn(column)
        tableView.allowsColumnResizing = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.gridStyleMask = .dashedHorizontalGridLineMask
        tableView.selectionHighlightStyle = .sourceList

        return tableView
    }
    
    private func createScrollView(for tableView: NSTableView) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }
    
    // MARK: - MainViewController
    
    func reloadLeft() {
        leftTableView.reloadData()
    }
    
    func reloadRight() {
        rightTableView.reloadData()
    }
    
    func resetToStop() {
        progressIndicator.isHidden = true
        progressIndicator.stopAnimation(nil)
        startStopButton.title = "Start"
        isRunning = false
    }
    
    // MARK: - Actions
    
    @objc private func startStopButtonAction() {
        if isRunning {
            presenter.didStopScanning()
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(nil)
            startStopButton.title = "Start"
        } else {
            presenter.didStartScanning()
            progressIndicator.startAnimation(nil)
            progressIndicator.isHidden = false
            startStopButton.title = "Stop"
        }

        isRunning.toggle()
    }
    
    @objc private func resetButtonAction() {
        presenter.resetConnection()
    }
}

// MARK: - NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == leftTableView {
            return presenter.leftDataSource.count
        } else {
            return presenter.rightDataSource.count
        }
    }

    func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("CellIdentifier")

        let cell = tableView.makeView(
            withIdentifier: cellIdentifier, owner: nil
            ) as? NSTableCellView ?? NSTableCellView()
        cell.identifier = cellIdentifier
        
        let label = NSTextField()
        label.isEditable = false
        label.isBordered = false

        
        if tableView == leftTableView {
            let connection = presenter.leftDataSource[row]
            let uuid = "uuid: " + connection.connectionId
            let name = " | name: " + (connection.connectionName ?? "nil")
            let rssi = " | Rssi: " + "\(connection.rssi)"
            let cellStringValue = uuid + name + rssi
            label.stringValue = cellStringValue
        } else {
            let connection = presenter.rightDataSource[row]
            let uuid = "uuid: " + connection.connectionId
            let name = " | name: " + (connection.connectionName ?? "nil")
            let rssi = " | Rssi: " + "\(connection.rssi)"
            let cellStringValue = uuid + name + rssi
            label.stringValue = cellStringValue
        }

        cell.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: cell.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: cell.trailingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true

        return cell
    }
}

// MARK: - NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        if tableView == leftTableView {
            presenter.selectConnection(index: leftTableView.selectedRow)
        }
    }
}
