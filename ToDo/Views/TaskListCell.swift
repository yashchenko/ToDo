//
//  TaskListCell.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

import UIKit

// MARK: - TaskListCell (for TaskListsViewController)

class TaskListCell: UITableViewCell {
    static let identifier = "TaskListCell" // Reuse identifier

    // UI Elements
    private let colorIndicator = UIView()
    private let nameLabel = UILabel()
    // private let taskCountLabel = UILabel() // Optional: Add if needed

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator // Show arrow for navigation
        backgroundColor = .clear

        // Color Indicator (small circle)
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        colorIndicator.layer.cornerRadius = 5 // Adjust size as needed

        // Name Label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.textColor = .label // Adapts to light/dark

        // Add subviews
        contentView.addSubview(colorIndicator)
        contentView.addSubview(nameLabel)

        // Constraints
        let padding: CGFloat = 15.0
        NSLayoutConstraint.activate([
            colorIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            colorIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 10),
            colorIndicator.heightAnchor.constraint(equalToConstant: 10),

            nameLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: padding),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding), // Allow space for accessory
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with list: TaskList) {
        nameLabel.text = list.name
        colorIndicator.backgroundColor = UIColor(hexString: list.colorHex) // Set color from hex
    }

    // Reset cell on reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        colorIndicator.backgroundColor = .clear
    }
}


// MARK: - TaskCell (for TaskListViewController)

class TaskCell: UITableViewCell {
    static let identifier = "TaskCell"

    // UI Elements
    private let completionIndicator = UIView() // Circle view
    private let titleLabel = UILabel()
    private let dueDateLabel = UILabel()
    private let priorityIndicator = UIView() // Small colored dot

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator
        backgroundColor = .clear

        // Completion Indicator
        completionIndicator.translatesAutoresizingMaskIntoConstraints = false
        completionIndicator.layer.cornerRadius = 10 // Half of width/height
        completionIndicator.layer.borderWidth = 1.5
        completionIndicator.layer.borderColor = UIColor.themeSecondaryText.cgColor

        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2 // Allow some wrapping

        // Due Date Label
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateLabel.font = UIFont.systemFont(ofSize: 13)
        dueDateLabel.textColor = .themeSecondaryText

        // Priority Indicator
        priorityIndicator.translatesAutoresizingMaskIntoConstraints = false
        priorityIndicator.layer.cornerRadius = 4 // Half of width/height
        priorityIndicator.isHidden = true // Hide by default

        // Stack view for title and due date
        let labelsStackView = UIStackView(arrangedSubviews: [titleLabel, dueDateLabel])
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 2

        // Add subviews
        contentView.addSubview(completionIndicator)
        contentView.addSubview(labelsStackView)
        contentView.addSubview(priorityIndicator)

        // Constraints
        let padding: CGFloat = 12.0
        NSLayoutConstraint.activate([
            // Completion Indicator
            completionIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            completionIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            completionIndicator.widthAnchor.constraint(equalToConstant: 20),
            completionIndicator.heightAnchor.constraint(equalToConstant: 20),

            // Labels Stack View
            labelsStackView.leadingAnchor.constraint(equalTo: completionIndicator.trailingAnchor, constant: padding),
            labelsStackView.trailingAnchor.constraint(equalTo: priorityIndicator.leadingAnchor, constant: -padding), // Space before priority
            labelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding / 1.5),
            labelsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding / 1.5),

            // Priority Indicator
            priorityIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding), // Space before accessory
            priorityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priorityIndicator.widthAnchor.constraint(equalToConstant: 8),
            priorityIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    func configure(with task: Task) {
        titleLabel.text = task.title

        // Due Date Label
        if let dueDate = task.dueDate {
             dueDateLabel.isHidden = false
             dueDateLabel.text = dueDate.formatted()
             // Style based on date and completion status
             if task.isCompleted {
                 dueDateLabel.textColor = .themeSecondaryText
             } else if dueDate.isToday {
                 dueDateLabel.textColor = .themeAccentOrange
             } else if dueDate.isPast {
                 dueDateLabel.textColor = .themeAccentRed
             } else {
                 dueDateLabel.textColor = .themeSecondaryText
             }
         } else {
             dueDateLabel.isHidden = true
             dueDateLabel.text = nil
         }

        // Priority Indicator
         switch task.priority {
         case .none:
             priorityIndicator.isHidden = true
         case .low:
             priorityIndicator.backgroundColor = .themePrimary // Blue
             priorityIndicator.isHidden = false
         case .medium:
             priorityIndicator.backgroundColor = .themeAccentOrange
             priorityIndicator.isHidden = false
         case .high:
             priorityIndicator.backgroundColor = .themeAccentRed
             priorityIndicator.isHidden = false
         }


        // Completion Styling
        if task.isCompleted {
            completionIndicator.backgroundColor = .themeAccentGreen
            completionIndicator.layer.borderColor = UIColor.themeAccentGreen.cgColor
            // Apply strikethrough
            let attributes: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.themeSecondaryText // Dim color
            ]
            titleLabel.attributedText = NSAttributedString(string: task.title, attributes: attributes)
            titleLabel.textColor = .themeSecondaryText // Ensure consistency
        } else {
            completionIndicator.backgroundColor = .clear
            completionIndicator.layer.borderColor = UIColor.themeSecondaryText.cgColor
            // Remove strikethrough
            titleLabel.attributedText = nil
            titleLabel.text = task.title // Set plain text
            titleLabel.textColor = .label
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        titleLabel.text = nil
        dueDateLabel.text = nil
        dueDateLabel.isHidden = true
        priorityIndicator.isHidden = true
        priorityIndicator.backgroundColor = .clear
        completionIndicator.backgroundColor = .clear
        completionIndicator.layer.borderColor = UIColor.themeSecondaryText.cgColor
    }
}

