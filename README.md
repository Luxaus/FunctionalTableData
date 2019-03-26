<img src="https://github.com/Shopify/FunctionalTableData/raw/master/Images/Banner.png" />

[![Build Status](https://travis-ci.org/Shopify/FunctionalTableData.svg)](https://travis-ci.org/Shopify/FunctionalTableData)

Functional Table Data implements a functional renderer for UITableView. You pass it a complete description of your table state, and Functional Table Data compares it with the previous render call to insert, update, and remove the sections and cells that have changed. This massively simplifies state management of complex UI.

No longer do you have to manually track the number of sections, cells, and indices of your UI. Build one method that generates your table state structure from your data. The provided `HostCell` generic makes it easy to add FunctionalTableData support to `UITableViewCell`s.

|         | Noteworthy features       |
----------|---------------------
💯 | Functional approach for maintaining table state
👷‍ | Reusable views and states
✅ | Unit tests
🔀 | Automatic diff in your states
❤️ | Used across Shopify's iOS apps
🙅 | No more IndexPath bookkeeping

## Installation

### Manual

Simply drag and drop `FunctionalTableData/FunctionalTableData.xcodeproj` into your Xcode project.

### Carthage

Add the following to your `Cartfile`:

```ruby
github "Shopify/FunctionalTableData"
```

## Getting started
To use the Functional Table Data (FTD) two things are required, one instance of UITableView, and an instance of the FTD itself. Once both are available, typically in a view controller's `viewDidLoad`, they are connected together using
`functionalTableData.tableView = yourTableViewInstance`. After this, every time we want to display/update the data we simply call `functionalTableData.renderAndDiff(sections)`.

For more information, read our [documentation](https://shopify.github.io/FunctionalTableData/).

## Usage

Check out the [demo app](https://github.com/Shopify/FunctionalTableData/blob/master/FunctionalTableDataDemo) for a fully interactive example.

Any time you want to update the data currently being displayed you generate the new state and pass it off to your instance of the Functional Table Data. The FTD is then responsible for computing the differences between the previous state and the next state and updating itself as necessary.

The `FunctionalTableData` holds onto an array of sections where each section has a key. This key must be unique across all sections but should be deterministic so that its possible to adjust the rows contained within that section without replacing the entire section itself.

```swift
let section = TableSection(key: "header-unique-key", rows: [])
```

Each section contains a series of rows where each row value must conform to the `CellConfigType` protocol.

```swift
/// The simplest possible version of a cell that displays a label.
/// Useful to get started, but in most cases a more robust state should be used allowing more customization.
typealias LabelCell = HostCell<UILabel, String, LayoutMarginsTableItemLayout>

let cells: [CellConfigType] = [
	LabelCell(key: "company", state: "Shopify") { view, state in
		view.text = state
	},
	LabelCell(key: "location", state: "🇨🇦") { view, state in
		view.text = state
	}
]
```

The rows themselves also have a key which must be unique inside of that section. This key is used to determine when new rows are added to a section, if any were removed, or if any moved to a different location.
Additionally, each `CellConfig` type implements an isEqual function to determine if two of them represent the same data being displayed. This allows for a single cell to perform a state change operation, that is, a toggle changing from its `off` to `on` state, a text value changing, etc.

After assigning the variable `rows` to our previously created `section`, all that is needed to display the data in the table view is this method.

```swift
functionalTableData.renderAndDiff([section])
```

<img src="https://github.com/Shopify/FunctionalTableData/raw/master/Images/Example1.png" />

Check out the [demo app](https://github.com/Shopify/FunctionalTableData/blob/master/FunctionalTableDataDemo) for a fully interactive example.

### Building new Cells
Knowing that a cell consists of a view and state let's start with a simple example, a cell that displays a label. By specifying the generic requirements of `HostCell`, the simplest possible example is one that takes an `UILabel` as its view, a `String` as its state and `LayoutMarginsTableItemLayout` as the layout (See `TableItemLayout` for more info).

```swift
typealias LabelCell = HostCell<UILabel, String, LayoutMarginsTableItemLayout>

// Usage
LabelCell(key: "company", state: "Shopify") { view, state in
	view.text = state
}
```

Although, the previous code is very useful to get started, in most cases a more robust state should be used allowing more customization. A better example would be something like this

```swift
typealias LabelCell = HostCell<UILabel, LabelState, LayoutMarginsTableItemLayout>

struct LabelState: Equatable {
	let text: String
	let alignment: NSTextAlignment
	let color: UIColor

	static func ==(lhs: LabelState, rhs: LabelState) -> Bool {
		return lhs.text == rhs.text && lhs.alignment == rhs.alignment && lhs.color == rhs.color
	}
}

// Usage
LabelCell(key: "company", state: LabelState(text: "Shopify",
                                            alignment: .center,
                                            color: .green)) { view, state in
	guard let state = state else {
		// If the state is `nil`, prepare this view to be reused
		view.text = ""
		view.textAlignment = .natural
		view.textColor = .black
		return
	}
	view.text = state.text
	view.textAlignment = state.alignment
	view.textColor = state.color
}
```

At the end of the day `HostCell` is just one of the possible implementations of `CellConfigType`, that's the underlying power of this framework.

### Building custom Cells

In order to build custom cells we will need:

1. A custom view class
2. An object to manage the view state

Let's build a view replicating a new iMessage cell

<img src="https://user-images.githubusercontent.com/7354919/54960747-30073200-4f1b-11e9-86c2-bb4b4fc4c5c1.png" />

The first step is to build the custom view:

```swift
class MessageView: UIView {
    let profilePicture = UIImageView()
    let nameLabel = UILabel()
    let messageLabel = UILabel()
    let timeStampLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        // implement your auto layout code
    }
}
```

Next, we'll build the `MessageViewState` struct that will take care of setting all the views properties:

```swift
struct Message {
    let name: String
    let image: UIImage
    let date: Date
    let text: String
    let id: String
}

struct MessageViewState: Equatable {
    let date: Date
    let name: String
    let message: String
    let image: UIImage

    init(message: Message) {
        self.date = message.date
        self.name = message.name
        self.message = message.text
        self.image = message.image
    }

    static func updateView(_ view: MessageView, state: MessageViewState?) {
        guard let state = state else { return }
        view.timeStampLabel.text = "\(state.date)"
        view.nameLabel.text = state.name
        view.messageLabel.text = state.message
        view.profilePicture.image = state.image
    }
}
```

Finally, we build the rows with our array of  `Message` and the table section using `renderAndDiff` 

```swift
private typealias MessageCell = HostCell<MessageView, MessageViewState, LayoutMarginsTableItemLayout>

private func render() {
    let rows: [CellConfigType] = messages.enumerated().map { index, message in
        return MessageCell(
            key: "message.id-\(index)",
            actions: CellActions(
                selectionAction: { _ in
                    print("\(message) selected")
                    return .selected
            },
                deselectionAction: { _ in
                    print("\(message) deselected")
                    return .deselected
            }),
            state: MessageViewState(message: message),
            cellUpdater: MessageViewState.updateView)
    }

    functionalData.renderAndDiff([TableSection(key: "section", rows: rows)])
}
```

The power of FunctionalTableData is made obvious when your table/collection view includes many different types of cells. Rather than have a massive `if-else` in `cellForRowAtIndexPath`. Since all cells are implementations of `CellConfigType`, it makes it incredbly easy to manage many different types of views and states.

## License
Functional Table Data is under the [MIT License](https://github.com/Shopify/FunctionalTableData/blob/master/LICENSE.txt)
