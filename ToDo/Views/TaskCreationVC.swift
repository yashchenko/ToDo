//
//  TaskCreationVC.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

import UIKit

// Allows creating a new Task for a specific list
class TaskCreationViewController: UIViewController {

    // MARK: - Properties
    private let listId: String // ID of the list to add the task to
    private let firebaseService = FirebaseService()

    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var titleTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "What needs to be done?"
        field.borderStyle = .roundedRect
        field.font = UIFont.systemFont(ofSize: 18)
        field.returnKeyType = .done
        field.delegate = self
        field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged) // To enable/disable Create button
        return field
    }()

    private lazy var notesTextView: UITextView = { // Optional notes
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 16)
        view.layer.borderColor = UIColor.themeSeparator.cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 5.0
        // Placeholder text handling
        view.text = "Notes (Optional)"
        view.textColor = .placeholderText
        view.delegate = self
        return view
    }()

    // Due Date and Priority UI (similar to Detail VC)
     private lazy var dueDatePicker = UIDatePicker()
     private lazy var dueDateSwitch = UISwitch()
     private lazy var prioritySegmentedControl = UISegmentedControl()

     private var createButton: UIBarButtonItem! // Declare here

    // MARK: - Initialization
    init(listId: String) {
        self.listId = listId
        super.init(nibName: nil, bundle: nil)
        self.title = "New Task"
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
        setupKeyboardDismissal()
    }

     override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         titleTextField.becomeFirstResponder() // Focus title field on appear
         registerForKeyboardNotifications()
     }

     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         view.endEditing(true)
         unregisterFromKeyboardNotifications()
     }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        // Create button, initially disabled
        createButton = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createTapped))
        createButton.isEnabled = false
        navigationItem.rightBarButtonItem = createButton
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
             contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
         ])
     }

     private func setupUIElements() {
         // Re-use setup logic similar to TaskDetailViewController for consistency

         // Due Date Picker setup
         dueDatePicker.datePickerMode = .date
         if #available(iOS 14.0, *) { dueDatePicker.preferredDatePickerStyle = .inline }
         else { dueDatePicker.preferredDatePickerStyle = .wheels }
         dueDatePicker.minimumDate = Calendar.current.startOfDay(for: Date())
         dueDatePicker.isHidden = true // Start hidden
         dueDatePicker.alpha = 0.0
         dueDateSwitch.addTarget(self, action: #selector(dueDateSwitchChanged), for: .valueChanged)


         // Priority Control setup
         let items = Task.TaskPriority.allCases.map { $0.description }
         prioritySegmentedControl = UISegmentedControl(items: items)
         prioritySegmentedControl.selectedSegmentTintColor = .themePrimary
         prioritySegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
         prioritySegmentedControl.selectedSegmentIndex = 0 // Default 'None'

         // Add elements to contentView
         contentView.addSubview(titleTextField)
         contentView.addSubview(notesTextView)
         contentView.addSubview(dueDateSwitch)
         contentView.addSubview(dueDatePicker)
         contentView.addSubview(prioritySegmentedControl)

         [titleTextField, notesTextView, dueDateSwitch, dueDatePicker, prioritySegmentedControl].forEach {
             $0.translatesAutoresizingMaskIntoConstraints = false
         }

         // Labels
         let notesLabel = createSectionLabel(text: "Notes")
         let dueDateLabel = createSectionLabel(text: "Due Date")
         let priorityLabel = createSectionLabel(text: "Priority")
         [notesLabel, dueDateLabel, priorityLabel].forEach {
             contentView.addSubview($0)
             $0.translatesAutoresizingMaskIntoConstraints = false
         }

         // Layout (Similar to Detail VC)
         let padding: CGFloat = 16.0
         let smallPadding: CGFloat = 8.0
         NSLayoutConstraint.activate([
              titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
              titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

              notesLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: padding * 1.5),
              notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: smallPadding),
              notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
              notesTextView.heightAnchor.constraint(equalToConstant: 100),

              dueDateLabel.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: padding * 1.5),
              dueDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              dueDateSwitch.centerYAnchor.constraint(equalTo: dueDateLabel.centerYAnchor),
              dueDateSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
              dueDatePicker.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: smallPadding),
              dueDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              dueDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

              priorityLabel.topAnchor.constraint(equalTo: dueDatePicker.bottomAnchor, constant: padding * 1.5),
              priorityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              prioritySegmentedControl.topAnchor.constraint(equalTo: priorityLabel.bottomAnchor, constant: smallPadding),
              prioritySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
              prioritySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
              prioritySegmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding * 2)
         ])
     }

     private func createSectionLabel(text: String) -> UILabel { // Helper
         let label = UILabel()
         label.text = text
         label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
         label.textColor = .themeSecondaryText
         return label
     }

     private func setupKeyboardDismissal() {
         let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
         tapGesture.cancelsTouchesInView = false
         view.addGestureRecognizer(tapGesture)
     }

    // MARK: - Actions
    @objc private func textFieldDidChange() {
        // Enable Create button only if title is not empty
        createButton.isEnabled = !(titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    @objc private func dueDateSwitchChanged() {
         let showPicker = dueDateSwitch.isOn
         UIView.animate(withDuration: 0.3) {
             self.dueDatePicker.isHidden = !showPicker
             self.dueDatePicker.alpha = showPicker ? 1.0 : 0.0
         }
     }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func createTapped() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorAlert(message: "Task title cannot be empty.")
            return
        }

        // Get values from UI
        let notes = (notesTextView.textColor == .placeholderText) ? nil : notesTextView.text
        let dueDate = dueDateSwitch.isOn ? dueDatePicker.date : nil
        let priorityRaw = prioritySegmentedControl.selectedSegmentIndex - 1
        let priority = Task.TaskPriority(rawValue: priorityRaw) ?? .none

        // Create the Task object
        let newTask = Task(title: title, listId: listId, notes: notes, dueDate: dueDate, priority: priority)

        // Show loading indicator? Maybe just disable button
        createButton.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false // Disable cancel too

        firebaseService.createTask(newTask) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success:
                    print("Task created successfully!")
                    self.dismiss(animated: true, completion: nil) // Dismiss on success
                case .failure(let error):
                    print("Failed to create task: \(error)")
                    self.showErrorAlert(message: "Failed to create task: \(error.localizedDescription)")
                    // Re-enable buttons on failure
                    self.createButton.isEnabled = true
                    self.navigationItem.leftBarButtonItem?.isEnabled = true
                }
            }
        }
    }

     private func showErrorAlert(message: String) {
         let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default))
         present(alert, animated: true)
     }
}

// MARK: - UITextFieldDelegate
extension TaskCreationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Dismiss keyboard
        return true
    }
}

// MARK: - UITextViewDelegate (for Notes placeholder)
extension TaskCreationViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Notes (Optional)"
            textView.textColor = .placeholderText
        }
    }
}

 // MARK: - Keyboard Handling
 extension TaskCreationViewController {
     // Add same keyboard handling as TaskDetailViewController if needed
     // (Register/unregister, keyboardWillShow/Hide adjusting scrollView insets)
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
          let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
          scrollView.contentInset = contentInsets
          scrollView.scrollIndicatorInsets = contentInsets

          var activeRect: CGRect?
          if titleTextField.isFirstResponder { activeRect = titleTextField.frame }
          else if notesTextView.isFirstResponder { activeRect = notesTextView.frame }

          if let rect = activeRect {
              let rectInScrollView = contentView.convert(rect, to: scrollView)
              scrollView.scrollRectToVisible(rectInScrollView, animated: true)
          }
      }

      @objc func keyboardWillHide(_ notification: Notification) {
          scrollView.contentInset = .zero
          scrollView.scrollIndicatorInsets = .zero
      }
 }
