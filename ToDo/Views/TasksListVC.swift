//
//  TasksListVC.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

import UIKit

// Shows the list of all Task Lists
class TaskListsViewController: UIViewController {

    // MARK: - Properties
    private let firebaseService = FirebaseService() // Direct instance for simplicity
    private var taskLists: [TaskList] = [] // Data source for the table

    // UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let emptyStateLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Lists"
        view.backgroundColor = .themeBackground
        setupNavigationBar()
        setupTableView()
        setupActivityIndicator()
        setupEmptyStateLabel()
        setupAddButton()
        setupEditButton() // Add Edit button
        fetchTaskLists() // Load data when the view loads
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Deselect row when coming back to this screen
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        // Optional: Refresh data every time view appears?
        // fetchTaskLists()
    }

    // MARK: - Setup UI
    private func setupNavigationBar() {
        // Use large titles on this main screen
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always // Or .automatic
        navigationController?.navigationBar.tintColor = .themePrimary // Color for buttons
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        // Use custom cell
        tableView.register(TaskListCell.self, forCellReuseIdentifier: TaskListCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 55 // Adjust as needed
        tableView.backgroundColor = .clear // Let VC background show through

        // Constraints to fill view
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .themePrimary
        activityIndicator.hidesWhenStopped = true
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

     private func setupEmptyStateLabel() {
         view.addSubview(emptyStateLabel)
         emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
         emptyStateLabel.text = "No lists yet.\nTap '+' to create one."
         emptyStateLabel.textColor = .themeSecondaryText
         emptyStateLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
         emptyStateLabel.textAlignment = .center
         emptyStateLabel.numberOfLines = 0
         emptyStateLabel.isHidden = true // Start hidden

         NSLayoutConstraint.activate([
             emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40), // Slightly above center
             emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
             emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
         ])
     }

    private func setupAddButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddButton)
        )
    }

     private func setupEditButton() {
         // Use the standard edit button item
         navigationItem.leftBarButtonItem = editButtonItem
         editButtonItem.isEnabled = false // Disable initially until lists are loaded
     }

    // Override setEditing to manage table view's editing state
     override func setEditing(_ editing: Bool, animated: Bool) {
         super.setEditing(editing, animated: animated)
         tableView.setEditing(editing, animated: animated)
     }


    // MARK: - Data Fetching
    private func fetchTaskLists() {
        showLoading(true) // Show indicator
        firebaseService.fetchTaskLists { [weak self] result in
            // IMPORTANT: Switch back to the main thread for UI updates
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.showLoading(false) // Hide indicator

                switch result {
                case .success(let lists):
                    self.taskLists = lists // Update data source
                    self.tableView.reloadData() // Refresh table view
                    self.updateUIState() // Check if empty, enable edit button
                case .failure(let error):
                    self.taskLists = [] // Clear lists on error
                    self.tableView.reloadData()
                    self.updateUIState()
                    self.showErrorAlert(message: error.localizedDescription) // Show error
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func didTapAddButton() {
        showAddListAlert()
    }

    private func showAddListAlert() {
        let alert = UIAlertController(title: "New List", message: "Enter a name for your list:", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "List Name"
            textField.autocapitalizationType = .sentences
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self, weak alert] _ in
            guard let name = alert?.textFields?.first?.text, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            self?.createNewList(name: name)
        })
        present(alert, animated: true)
    }

    private func createNewList(name: String) {
        showLoading(true)
        // Determine next orderIndex
        let nextOrderIndex = (taskLists.map { $0.orderIndex }.max() ?? -1) + 1
        let newList = TaskList(name: name, orderIndex: nextOrderIndex) // Create model

        firebaseService.createTaskList(newList) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.showLoading(false)
                switch result {
                case .success:
                    // Optimistically add to list and reload, or refetch? Refetch is simpler.
                    print("List '\(name)' created successfully. Refreshing lists.")
                    self.fetchTaskLists() // Refresh the whole list view
                case .failure(let error):
                    self.showErrorAlert(message: "Failed to create list: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteList(at indexPath: IndexPath) {
         let listToDelete = taskLists[indexPath.row]
         showLoading(true)

         firebaseService.deleteTaskList(listId: listToDelete.id) { [weak self] result in
             DispatchQueue.main.async {
                 guard let self = self else { return }
                 self.showLoading(false)
                 switch result {
                 case .success:
                     print("List '\(listToDelete.name)' and its tasks deleted successfully. Refreshing.")
                     // Remove locally and update table, or just refetch
                     self.taskLists.remove(at: indexPath.row)
                     self.tableView.deleteRows(at: [indexPath], with: .automatic)
                     self.updateUIState() // Check empty state again
                 case .failure(let error):
                     self.showErrorAlert(message: "Failed to delete list: \(error.localizedDescription)")
                 }
             }
         }
     }

    // MARK: - UI Helpers
    private func showLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            // Optionally disable buttons
            navigationItem.rightBarButtonItem?.isEnabled = false
            editButtonItem.isEnabled = false
             tableView.isHidden = true // Hide table while loading initially
             emptyStateLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            navigationItem.rightBarButtonItem?.isEnabled = true
            // edit button enabled based on list count in updateUIState
             tableView.isHidden = taskLists.isEmpty // Show table if not empty
        }
    }

    private func showErrorAlert(message: String) {
        // ---> ADD THIS CHECK <---
        guard self.presentedViewController == nil else {
            print("⚠️ Attempted to present error alert while another view controller is already presented. Skipping.")
            // Optionally, you could queue the error message to show later
            return
        }
        // ---> END OF ADDED CHECK <---

        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
     private func updateUIState() {
         let isEmpty = taskLists.isEmpty
         emptyStateLabel.isHidden = !isEmpty
         tableView.isHidden = isEmpty
         editButtonItem.isEnabled = !isEmpty // Enable edit only if there are lists
     }
}

// MARK: - UITableViewDataSource
extension TaskListsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskLists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskListCell.identifier, for: indexPath) as? TaskListCell else {
            return UITableViewCell() // Fallback
        }
        let list = taskLists[indexPath.row]
        cell.configure(with: list)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedList = taskLists[indexPath.row]
        // Create and push the TaskListViewController
        let taskListVC = TaskListViewController(list: selectedList) // Pass the selected list
        navigationController?.pushViewController(taskListVC, animated: true)
    }

     // --- Editing Support ---

     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
         return true // Allow deleting all rows
     }

     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
         if editingStyle == .delete {
             // Show confirmation alert before deleting
             let listToDelete = taskLists[indexPath.row]
             let confirmAlert = UIAlertController(title: "Delete List", message: "Delete \"\(listToDelete.name)\"? This will also delete all its tasks.", preferredStyle: .alert)
             confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
             confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                 self?.deleteList(at: indexPath)
             })
             present(confirmAlert, animated: true)
         }
     }

     // Reordering (Optional, uncomment if needed)
     /*
     func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
         return true // Allow moving rows
     }

     func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
         // 1. Update local data source array
         let movedList = taskLists.remove(at: sourceIndexPath.row)
         taskLists.insert(movedList, at: destinationIndexPath.row)

         // 2. Update orderIndex property for all lists
         for (index, list) in taskLists.enumerated() {
             // Need to make TaskList a class or update via index if struct
             // Assuming TaskList is a struct: taskLists[index].orderIndex = index
             // This requires TaskList `var` properties or a different approach.
             // Let's skip persistent reordering for simplicity for now.
             // If needed, make TaskList a class or implement a batch update.
         }
         print("Reordering locally - Persistent update needed for orderIndex.")
         // TODO: Call FirebaseService to update orderIndexes on the backend
         // Example: firebaseService.updateListOrder(taskLists) { ... }
     }
     */
}
