//
//  TaskDetailVC.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

import UIKit

// Shows details of a single Task and allows editing
class TaskDetailViewController: UIViewController {

    // MARK: - Properties
    private var task: Task // The task being displayed/edited (use var to allow modification)
    private let firebaseService = FirebaseService()

    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView() // Content view inside scroll view

    private lazy var titleTextField: UITextField = {
        let field = UITextField()
        field.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        field.placeholder = "Task Title"
        field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return field
    }()

    private lazy var notesTextView: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 17)
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.themeSeparator.cgColor // Add border for clarity
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 5.0
        view.delegate = self // To update view model on change
        return view
    }()

    private lazy var dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        if #available(iOS 14.0, *) {
             picker.preferredDatePickerStyle = .inline // Modern style
         } else {
             picker.preferredDatePickerStyle = .wheels // Fallback for older iOS
         }
        picker.addTarget(self, action: #selector(dateOrPriorityChanged), for: .valueChanged)
        return picker
    }()
     private lazy var dueDateSwitch: UISwitch = { // Allow removing due date
         let sw = UISwitch()
         sw.addTarget(self, action: #selector(dueDateSwitchChanged), for: .valueChanged)
         return sw
     }()


    private lazy var prioritySegmentedControl: UISegmentedControl = {
         let items = Task.TaskPriority.allCases.map { $0.description }
         let control = UISegmentedControl(items: items)
         control.selectedSegmentTintColor = .themePrimary
         control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
         control.addTarget(self, action: #selector(dateOrPriorityChanged), for: .valueChanged)
         return control
     }()

     private let activityIndicator = UIActivityIndicatorView(style: .medium) // Smaller indicator for updates

    // MARK: - Initialization
    init(task: Task) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
        self.title = "Task Details"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themeBackground
        setupNavigationBar()
        setupScrollView()
        setupUIElements()
        setupActivityIndicator()
        populateUI()
        setupKeyboardDismissal()
    }

     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         registerForKeyboardNotifications()
     }

     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         // Make sure the last change is saved when leaving the screen
         saveChangesIfNeeded()
         unregisterFromKeyboardNotifications()
     }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        // Add a save button? Or save automatically? Auto-save is simpler.
         activityIndicator.hidesWhenStopped = true
         navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            // Important: Content view width must equal scroll view width for vertical scrolling
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupUIElements() {
        // Add elements to contentView
        contentView.addSubview(titleTextField)
        contentView.addSubview(notesTextView)
        contentView.addSubview(dueDateSwitch)
        contentView.addSubview(dueDatePicker)
        contentView.addSubview(prioritySegmentedControl)

        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        dueDateSwitch.translatesAutoresizingMaskIntoConstraints = false
        dueDatePicker.translatesAutoresizingMaskIntoConstraints = false
        prioritySegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        // Basic Labels
        let notesLabel = createSectionLabel(text: "Notes")
        let dueDateLabel = createSectionLabel(text: "Due Date")
        let priorityLabel = createSectionLabel(text: "Priority")

        contentView.addSubview(notesLabel)
        contentView.addSubview(dueDateLabel)
        contentView.addSubview(priorityLabel)

        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false

        // Layout within contentView
        let padding: CGFloat = 16.0
        let smallPadding: CGFloat = 8.0

        NSLayoutConstraint.activate([
            // Title
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Notes
            notesLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: padding * 1.5),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: smallPadding),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            notesTextView.heightAnchor.constraint(equalToConstant: 120), // Adjust as needed

            // Due Date
            dueDateLabel.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: padding * 1.5),
            dueDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            // Switch aligned with label
            dueDateSwitch.centerYAnchor.constraint(equalTo: dueDateLabel.centerYAnchor),
            dueDateSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            dueDatePicker.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: smallPadding),
            dueDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            dueDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Priority
            priorityLabel.topAnchor.constraint(equalTo: dueDatePicker.bottomAnchor, constant: padding * 1.5),
            priorityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            priorityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            prioritySegmentedControl.topAnchor.constraint(equalTo: priorityLabel.bottomAnchor, constant: smallPadding),
            prioritySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            prioritySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            // Make sure content view's bottom is tied to the last element
            prioritySegmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2) // Add bottom padding
        ])
    }

     private func createSectionLabel(text: String) -> UILabel {
         let label = UILabel()
         label.text = text
         label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
         label.textColor = .themeSecondaryText
         return label
     }

     private func setupActivityIndicator() {
         // Already added to navigation bar item
     }

     private func setupKeyboardDismissal() {
         let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
         tapGesture.cancelsTouchesInView = false // Allow taps on controls
         view.addGestureRecognizer(tapGesture)
     }


    // MARK: - Populate UI
    private func populateUI() {
        titleTextField.text = task.title
        notesTextView.text = task.notes ?? ""
         // Handle placeholder for notesTextView
         if notesTextView.text.isEmpty {
             notesTextView.text = "Add notes..."
             notesTextView.textColor = .placeholderText // Use standard placeholder color
         } else {
             notesTextView.textColor = .label // Use standard text color
         }


        if let dueDate = task.dueDate {
            dueDatePicker.date = dueDate
            dueDatePicker.isHidden = false
            dueDateSwitch.isOn = true
        } else {
            dueDatePicker.isHidden = true
            dueDateSwitch.isOn = false
            // Optional: Set default date if user enables it
             dueDatePicker.date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        prioritySegmentedControl.selectedSegmentIndex = task.priority.rawValue + 1 // Adjust for .none index
    }

    // MARK: - Actions & Saving
    @objc private func textFieldDidChange() {
        // Auto-save on text change (can add debouncer later if needed)
        saveChangesIfNeeded()
    }

     @objc private func dateOrPriorityChanged() {
         saveChangesIfNeeded()
     }

     @objc private func dueDateSwitchChanged() {
         let hasDueDate = dueDateSwitch.isOn
         // Animate visibility
         UIView.animate(withDuration: 0.3) {
             self.dueDatePicker.isHidden = !hasDueDate
             self.dueDatePicker.alpha = hasDueDate ? 1.0 : 0.0
         }
         // Trigger save
         saveChangesIfNeeded()
     }


    // This function checks if data differs and calls Firebase
    private func saveChangesIfNeeded() {
        // Create a Task struct with current UI values
         let currentTitle = titleTextField.text ?? ""
         let currentNotes = (notesTextView.textColor == .placeholderText || notesTextView.text == "Add notes...") ? nil : notesTextView.text
         let currentDueDate = dueDateSwitch.isOn ? dueDatePicker.date : nil
         let currentPriorityRaw = prioritySegmentedControl.selectedSegmentIndex - 1
         let currentPriority = Task.TaskPriority(rawValue: currentPriorityRaw) ?? .none

        // Compare with the original task state
        var changed = false
        if currentTitle != task.title { changed = true; task.title = currentTitle }
        if currentNotes != task.notes { changed = true; task.notes = currentNotes }
        if currentDueDate != task.dueDate { changed = true; task.dueDate = currentDueDate }
        if currentPriority != task.priority { changed = true; task.priority = currentPriority }

        if changed {
            print("Changes detected, saving...")
             activityIndicator.startAnimating()
             // Disable UI? Maybe not for auto-save, just show indicator.

            // Important: Update the local task's updatedAt timestamp BEFORE saving
            task.updatedAt = Date()

            firebaseService.updateTask(task) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                     self.activityIndicator.stopAnimating()
                    switch result {
                    case .success:
                        print("Task '\(self.task.title)' updated successfully.")
                        // Optionally show subtle confirmation?
                    case .failure(let error):
                        print("Error updating task: \(error.localizedDescription)")
                        self.showErrorAlert(message: "Failed to save changes: \(error.localizedDescription)")
                        // Consider reverting UI changes or re-fetching data on error?
                        // For auto-save, maybe just log the error.
                    }
                }
            }
        } else {
            // print("No changes detected.")
        }
    }

    private func showErrorAlert(message: String) {
         let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default))
         present(alert, animated: true)
     }

}

// MARK: - UITextViewDelegate
 extension TaskDetailViewController: UITextViewDelegate {
     func textViewDidBeginEditing(_ textView: UITextView) {
         if textView.textColor == .placeholderText {
             textView.text = nil
             textView.textColor = .label
         }
     }

     func textViewDidEndEditing(_ textView: UITextView) {
         if textView.text.isEmpty {
             textView.text = "Add notes..."
             textView.textColor = .placeholderText
         }
         // Trigger save when user finishes editing notes
         saveChangesIfNeeded()
     }

     // Optional: Auto-save as user types notes (can be intensive)
     // func textViewDidChange(_ textView: UITextView) {
     //    saveChangesIfNeeded()
     // }
 }

 // MARK: - Keyboard Handling (Adjust ScrollView Insets)
 extension TaskDetailViewController {
     func registerForKeyboardNotifications() {
         NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
     }

     func unregisterFromKeyboardNotifications() {
         NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
         NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
     }

     @objc func keyboardWillShow(_ notification: Notification) {
         guard let userInfo = notification.userInfo,
               let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

         // Adjust scroll view's bottom inset to make space for keyboard
         let keyboardHeight = keyboardFrame.height
         scrollView.contentInset.bottom = keyboardHeight
         scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight

         // Find the currently active text input
          var activeFieldFrame: CGRect?
          if titleTextField.isFirstResponder {
              activeFieldFrame = titleTextField.frame
          } else if notesTextView.isFirstResponder {
              activeFieldFrame = notesTextView.frame
          }

         // Scroll to make the active field visible
         if let activeFrame = activeFieldFrame {
             // Convert frame to scroll view's coordinate space
             let fieldRectInScrollView = contentView.convert(activeFrame, to: scrollView)
             // Calculate the visible rect *excluding* the keyboard area
             var visibleRect = scrollView.frame
             visibleRect.size.height -= keyboardHeight
             // If the active field isn't fully visible, scroll it up
             if !visibleRect.contains(fieldRectInScrollView.origin) {
                 // Scroll just enough to bring the bottom of the field into view
                 let scrollPoint = CGPoint(x: 0, y: fieldRectInScrollView.maxY - visibleRect.height + 10) // Add padding
                 scrollView.setContentOffset(scrollPoint, animated: true)
             }
         }
     }

     @objc func keyboardWillHide(_ notification: Notification) {
         // Reset insets when keyboard hides
         scrollView.contentInset = .zero
         scrollView.verticalScrollIndicatorInsets = .zero
     }
 }
