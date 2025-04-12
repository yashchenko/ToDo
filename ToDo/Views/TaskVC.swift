//
//  TaskVC.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

import UIKit

// Shows the tasks within a specific Task List
class TaskListViewController: UIViewController {

    // MARK: - Properties
    private let taskList: TaskList // The list we are showing tasks for
    private let firebaseService = FirebaseService()
    private var tasks: [Task] = [] // Data source

    // Computed properties to separate tasks for sections
     private var incompleteTasks: [Task] {
         tasks.filter { !$0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
     }
     private var completedTasks: [Task] {
         tasks.filter { $0.isCompleted }.sorted { $0.updatedAt > $1.updatedAt } // Sort by completion time
     }

    // UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped) // Or .plain
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let emptyStateLabel = UILabel()

    // Enum for table view sections
    private enum Section: Int {
        case incomplete = 0
        case completed = 1
    }

    // MARK: - Initialization
    // Receive the TaskList object to display
    init(list: TaskList) {
        self.taskList = list
        super.init(nibName: nil, bundle: nil)
        self.title = list.name // Set title from the list name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themeBackground
        setupNavigationBar()
        setupTableView()
        setupActivityIndicator()
        setupEmptyStateLabel()
        setupAddButton()
        fetchTasks()
    }

     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         // Refresh tasks when the view appears? Maybe needed after task creation/update
         fetchTasks()
         // Deselect row if returning
         if let selectedPath = tableView.indexPathForSelectedRow {
             tableView.deselectRow(at: selectedPath, animated: true)
         }
     }

    // MARK: - Setup UI
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never // Use standard title size here
         navigationController?.navigationBar.tintColor = .themePrimary
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        // Dynamic row height might be better if titles wrap
        // tableView.rowHeight = UITableView.automaticDimension
        // tableView.estimatedRowHeight = 60

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
         emptyStateLabel.text = "No tasks in this list.\nTap '+' to add one."
         emptyStateLabel.textColor = .themeSecondaryText
         emptyStateLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
         emptyStateLabel.textAlignment = .center
         emptyStateLabel.numberOfLines = 0
         emptyStateLabel.isHidden = true

         NSLayoutConstraint.activate([
             emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
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

    // MARK: - Data Fetching
    private func fetchTasks() {
        showLoading(true)
        firebaseService.fetchTasksForList(listId: taskList.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.showLoading(false)
                switch result {
                case .success(let fetchedTasks):
                    self.tasks = fetchedTasks
                    self.tableView.reloadData()
                    self.updateUIState()
                case .failure(let error):
                    self.tasks = []
                    self.tableView.reloadData()
                    self.updateUIState()
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Actions
    @objc private func didTapAddButton() {
        // Navigate to Task Creation screen
         let creationVC = TaskCreationViewController(listId: taskList.id)
         let navController = UINavigationController(rootViewController: creationVC)
         // Present modally
         present(navController, animated: true, completion: nil)
    }

    private func toggleTaskCompletion(at indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        var taskToUpdate: Task
        // Get the task from the correct array
        if section == .incomplete {
            taskToUpdate = incompleteTasks[indexPath.row]
        } else {
            taskToUpdate = completedTasks[indexPath.row]
        }

        // Toggle the status
        taskToUpdate.isCompleted.toggle()
        taskToUpdate.updatedAt = Date() // Update timestamp

        // Show loading indicator while updating
         showLoading(true)

        // Update in Firebase
        firebaseService.updateTask(taskToUpdate) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                 self.showLoading(false) // Hide indicator regardless of outcome

                switch result {
                case .success:
                    print("Task '\(taskToUpdate.title)' completion updated.")
                    // Find the task in the main 'tasks' array and update it
                    if let index = self.tasks.firstIndex(where: { $0.id == taskToUpdate.id }) {
                        self.tasks[index] = taskToUpdate
                        // Reload the table to reflect the change (moves between sections)
                        self.tableView.reloadData()
                        self.updateUIState()
                    } else {
                         // Task not found locally? Refresh from server.
                         self.fetchTasks()
                     }

                case .failure(let error):
                    self.showErrorAlert(message: "Failed to update task: \(error.localizedDescription)")
                    // Optionally revert the local change if needed, but reloading is safer
                    // self.fetchTasks() // Re-fetch to ensure consistency
                }
            }
        }
    }

     private func deleteTask(at indexPath: IndexPath) {
         guard let section = Section(rawValue: indexPath.section) else { return }
         let taskToDelete = (section == .incomplete) ? incompleteTasks[indexPath.row] : completedTasks[indexPath.row]

         showLoading(true)
         firebaseService.deleteTask(taskId: taskToDelete.id) { [weak self] result in
             DispatchQueue.main.async {
                 guard let self = self else { return }
                 self.showLoading(false)
                 switch result {
                 case .success:
                     print("Task '\(taskToDelete.title)' deleted.")
                     // Remove locally
                     if let index = self.tasks.firstIndex(where: { $0.id == taskToDelete.id }) {
                         self.tasks.remove(at: index)
                         // Animate deletion from table view
                         self.tableView.deleteRows(at: [indexPath], with: .automatic)
                         self.updateUIState()
                     } else {
                         self.fetchTasks() // Refresh if local state is inconsistent
                     }
                 case .failure(let error):
                     self.showErrorAlert(message: "Failed to delete task: \(error.localizedDescription)")
                 }
             }
         }
     }

    // MARK: - UI Helpers (Similar to TaskListsVC)
    private func showLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            tableView.alpha = 0.5 // Dim table view slightly
            view.isUserInteractionEnabled = false
        } else {
            activityIndicator.stopAnimating()
            tableView.alpha = 1.0
            view.isUserInteractionEnabled = true
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
         let isEmpty = tasks.isEmpty
         emptyStateLabel.isHidden = !isEmpty
         tableView.isHidden = isEmpty
     }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        // Always potentially have 2 sections, but hide header if one is empty
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionEnum = Section(rawValue: section) else { return 0 }
        return sectionEnum == .incomplete ? incompleteTasks.count : completedTasks.count
    }

     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
         guard let sectionEnum = Section(rawValue: section) else { return nil }
         let hasIncomplete = !incompleteTasks.isEmpty
         let hasCompleted = !completedTasks.isEmpty

         switch sectionEnum {
         case .incomplete:
             return hasIncomplete ? "To Do" : nil // Only show if rows exist
         case .completed:
             // Only show if completed rows exist AND there are also incomplete rows
             return (hasCompleted && hasIncomplete) ? "Completed" : nil
         }
     }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.identifier, for: indexPath) as? TaskCell,
              let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        let task = (section == .incomplete) ? incompleteTasks[indexPath.row] : completedTasks[indexPath.row]
        cell.configure(with: task)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }
        let selectedTask = (section == .incomplete) ? incompleteTasks[indexPath.row] : completedTasks[indexPath.row]

        // Navigate to Task Detail screen
         let detailVC = TaskDetailViewController(task: selectedTask)
         navigationController?.pushViewController(detailVC, animated: true)
    }

    // --- Swipe Actions ---
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Delete Action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteTask(at: indexPath)
            completion(true) // Indicate action was handled
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }
        let task = (section == .incomplete) ? incompleteTasks[indexPath.row] : completedTasks[indexPath.row]

        // Completion Action
        let title = task.isCompleted ? "Reopen" : "Complete"
        let completionAction = UIContextualAction(style: .normal, title: title) { [weak self] _, _, completion in
            self?.toggleTaskCompletion(at: indexPath)
            completion(true)
        }
        completionAction.backgroundColor = task.isCompleted ? .themeAccentOrange : .themeAccentGreen

        return UISwipeActionsConfiguration(actions: [completionAction])
    }

     // Adjust spacing between sections visually
     func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         // Only add significant height if the header title is actually shown
         if self.tableView(tableView, titleForHeaderInSection: section) != nil {
             return 30.0 // Height when header title is visible
         } else {
             return 5.0 // Minimal height otherwise
         }
     }

     func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
         return 5.0 // Minimal footer space
     }

     // Customize header appearance (Optional)
     func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
         if let headerView = view as? UITableViewHeaderFooterView {
             headerView.textLabel?.textColor = .themeSecondaryText
             headerView.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
             headerView.textLabel?.text = headerView.textLabel?.text?.uppercased() // Uppercase title
         }
     }
}
