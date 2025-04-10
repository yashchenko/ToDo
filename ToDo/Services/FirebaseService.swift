//
//  FirebaseService.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

//import UIKit
//
//// Handles all communication with Firebase Realtime Database REST API
//class FirebaseService {
//
//    // Your Firebase Realtime Database URL (Get this from Firebase Console -> Realtime Database)
//    // IMPORTANT: Replace this with your actual database URL!
//    private let databaseURLString = "https://todo-2c4be-default-rtdb.europe-west1.firebasedatabase.app/"
//    // Shared URLSession for network requests
//    private let session = URLSession.shared
//
//    // Helper to build the full URL for a path (e.g., "tasks", "taskLists/list123")
//    private func buildURL(for path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
//        guard !databaseURLString.contains("your-project-id") else {
//             print("🔥🔥🔥 ERROR: Update databaseURLString in FirebaseService.swift! 🔥🔥🔥")
//             // You could fatalError here during development to ensure it's set
//             // fatalError("Update databaseURLString in FirebaseService.swift!")
//             return nil
//        }
//        // Ensure base URL ends with / and path doesn't start with /
//        let baseURL = databaseURLString.hasSuffix("/") ? databaseURLString : databaseURLString + "/"
//        let cleanPath = path.starts(with: "/") ? String(path.dropFirst()) : path
//
//        // Append ".json" for Firebase REST API
//        let fullPath = baseURL + cleanPath + ".json"
//
//        guard var components = URLComponents(string: fullPath) else {
//            print("Error creating URL components for path: \(path)")
//            return nil
//        }
//
//        // Add query parameters if any (for filtering/ordering)
//        components.queryItems = queryItems
//
//        return components.url
//    }
//
//    // MARK: - TaskList Operations
//
//    // Fetch all task lists
//    func fetchTaskLists(completion: @escaping (Result<[TaskList], FirebaseError>) -> Void) {
//        guard let url = buildURL(for: "taskLists") else {
//            completion(.failure(.invalidURL("taskLists")))
//            return
//        }
//
//        performRequest(url: url, method: "GET") { result in
//            switch result {
//            case .success(let data):
//                // Firebase returns lists as a dictionary { "listId1": { listData1 }, "listId2": { ... } }
//                guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
//                    // Handle empty case or null response from Firebase
//                     if String(data: data, encoding: .utf8) == "null" || data.isEmpty {
//                        completion(.success([])) // Return empty array if no lists
//                        return
//                    }
//                    completion(.failure(.decodingError(NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected dictionary of TaskLists"]))))
//                    return
//                }
//                // Convert each value dictionary into a TaskList object
//                let lists = dictionary.compactMap { TaskList.fromDictionary($0.value) }
//                                     .sorted { $0.orderIndex < $1.orderIndex } // Sort by orderIndex
//                completion(.success(lists))
//
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    // Create a new task list
//    func createTaskList(_ list: TaskList, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
//        // Use PUT request with the list's ID in the path
//        guard let url = buildURL(for: "taskLists/\(list.id)") else {
//            completion(.failure(.invalidURL("taskLists/\(list.id)")))
//            return
//        }
//        let dictionary = list.toDictionaryForUpdate() // Get data to send
//
//        performRequest(url: url, method: "PUT", body: dictionary) { result in
//            switch result {
//            case .success: // PUT success often returns the written data or null, we just need success status
//                completion(.success(()))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    // Delete a task list (and its tasks - IMPORTANT)
//    func deleteTaskList(listId: String, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
//        // Step 1: Delete the list entry itself
//        guard let listURL = buildURL(for: "taskLists/\(listId)") else {
//            completion(.failure(.invalidURL("taskLists/\(listId)")))
//            return
//        }
//
//        performRequest(url: listURL, method: "DELETE") { [weak self] listDeleteResult in
//             guard let self = self else { return }
//
//            switch listDeleteResult {
//            case .success:
//                print("Successfully deleted TaskList: \(listId)")
//                // Step 2: Fetch and delete associated tasks (Best effort)
//                self.fetchTasksForList(listId: listId) { fetchResult in
//                    switch fetchResult {
//                    case .success(let tasks):
//                        if tasks.isEmpty {
//                            print("No tasks found for list \(listId) to delete.")
//                            completion(.success(())) // Main delete succeeded
//                            return
//                        }
//                        print("Found \(tasks.count) tasks for list \(listId). Deleting...")
//                        let group = DispatchGroup()
//                        var firstError: FirebaseError? = nil
//
//                        for task in tasks {
//                            group.enter()
//                            self.deleteTask(taskId: task.id) { taskDeleteResult in
//                                if case .failure(let error) = taskDeleteResult, firstError == nil {
//                                    firstError = error // Store the first error encountered
//                                    print("⚠️ Error deleting task \(task.id): \(error.localizedDescription)")
//                                }
//                                group.leave()
//                            }
//                        }
//
//                        group.notify(queue: .main) {
//                            if let error = firstError {
//                                // Report failure if any task deletion failed
//                                completion(.failure(.operationFailed("Failed to delete one or more tasks for list \(listId). Error: \(error.localizedDescription)")))
//                            } else {
//                                print("Successfully deleted all tasks for list \(listId).")
//                                completion(.success(())) // Both list and tasks deleted
//                            }
//                        }
//
//                    case .failure(let fetchError):
//                        // If fetching tasks failed, report list deletion succeeded but tasks might remain
//                         print("⚠️ Could not fetch tasks for deletion (list: \(listId)). Error: \(fetchError.localizedDescription)")
//                        completion(.failure(.operationFailed("List deleted, but failed to fetch/delete associated tasks.")))
//                    }
//                }
//
//            case .failure(let error):
//                // If deleting the list itself failed, report that
//                completion(.failure(error))
//            }
//        }
//    }
//
//     // Update a task list (e.g., reordering) - Using PUT replaces the whole object
//     func updateTaskList(_ list: TaskList, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
//         guard let url = buildURL(for: "taskLists/\(list.id)") else {
//             completion(.failure(.invalidURL("taskLists/\(list.id)")))
//             return
//         }
//         let dictionary = list.toDictionaryForUpdate()
//
//         performRequest(url: url, method: "PUT", body: dictionary) { result in
//             switch result {
//             case .success:
//                 completion(.success(()))
//             case .failure(let error):
//                 completion(.failure(error))
//             }
//         }
//     }
//
//
//    // MARK: - Task Operations
//
//    // Fetch tasks for a specific list ID
//     func fetchTasksForList(listId: String, completion: @escaping (Result<[Task], FirebaseError>) -> Void) {
//         // Use query parameters to filter by listId
//         let queryItems = [
//             URLQueryItem(name: "orderBy", value: "\"listId\""), // IMPORTANT: Value needs quotes inside quotes for strings
//             URLQueryItem(name: "equalTo", value: "\"\(listId)\"") // IMPORTANT: Value needs quotes inside quotes
//         ]
//         guard let url = buildURL(for: "tasks", queryItems: queryItems) else {
//             completion(.failure(.invalidURL("tasks?orderBy=\"listId\"&equalTo=\"\(listId)\"")))
//             return
//         }
//
//         performRequest(url: url, method: "GET") { result in
//             switch result {
//             case .success(let data):
//                 // Filtered results are also returned as a dictionary { "taskId1": { taskData1 }, ... }
//                 guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
//                     if String(data: data, encoding: .utf8) == "null" || data.isEmpty {
//                         completion(.success([])) // No tasks found for this list
//                         return
//                     }
//                     completion(.failure(.decodingError(NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Expected dictionary of Tasks"]))))
//                     return
//                 }
//                 let tasks = dictionary.compactMap { Task.fromDictionary($0.value) }
//                                      .sorted { $0.createdAt > $1.createdAt } // Sort by creation date (newest first)
//                 completion(.success(tasks))
//             case .failure(let error):
//                 completion(.failure(error))
//             }
//         }
//     }
//
//
//    // Create a new task
//     func createTask(_ task: Task, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
//         guard let url = buildURL(for: "tasks/\(task.id)") else {
//             completion(.failure(.invalidURL("tasks/\(task.id)")))
//             return
//         }
//         let dictionary = task.toDictionaryForUpdate()
//
//         performRequest(url: url, method: "PUT", body: dictionary) { result in
//             switch result {
//             case .success:
//                 completion(.success(()))
//             case .failure(let error):
//                 completion(.failure(error))
//             }
//         }
//     }
//
//    // Update an existing task
//     func updateTask(_ task: Task, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
//         guard let url = buildURL(for: "tasks/\(task.id)") else {
//             completion(.failure(.invalidURL("tasks/\(task.id)")))
//             return
//         }
//         let dictionary = task.toDictionaryForUpdate() // Gets current data + new updatedAt
//
//         performRequest(url: url, method: "PUT", body: dictionary) { result in
//             switch result {
//             case .success:
//                 completion(.success(()))
//             case .failure(let error):
//                 completion(.failure(error))
//             }
//         }
//     }
//
//    // Delete a task
//     func deleteTask(taskId: String, completion: @escaping (Result<Void, FirebaseError>) -> Void) {
//         guard let url = buildURL(for: "tasks/\(taskId)") else {
//             completion(.failure(.invalidURL("tasks/\(taskId)")))
//             return
//         }
//
//         performRequest(url: url, method: "DELETE") { result in
//             switch result {
//             case .success:
//                 completion(.success(()))
//             case .failure(let error):
//                 completion(.failure(error))
//             }
//         }
//     }
//
//
//    // MARK: - Private Generic Request Helper
//
//    // Reusable function to perform URLSession requests
//    private func performRequest(url: URL, method: String, body: [String: Any]? = nil, completion: @escaping (Result<Data, FirebaseError>) -> Void) {
//
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        request.addValue("application/json", forHTTPHeaderField: "Accept") // Expect JSON back
//
//        // Add body if provided (for PUT, POST, PATCH)
//        if let body = body {
//            do {
//                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
//                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            } catch {
//                completion(.failure(.encodingError(error)))
//                return
//            }
//        }
//
//        // Perform the data task
//        let task = session.dataTask(with: request) { data, response, error in
//            // 1. Handle basic network errors (connection, etc.)
//            if let error = error {
//                completion(.failure(.requestFailed(error)))
//                return
//            }
//
//            // 2. Check for valid HTTP response
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(.invalidResponse))
//                return
//            }
//
//            // 3. Check HTTP status code
//            guard (200...299).contains(httpResponse.statusCode) else {
//                completion(.failure(.badStatusCode(httpResponse.statusCode)))
//                return
//            }
//
//            // 4. Check if data exists (might be empty on success for DELETE/PUT)
//            guard let receivedData = data else {
//                // For DELETE or successful PUT/PATCH, empty data might be okay
//                if method == "DELETE" || method == "PUT" || method == "PATCH" {
//                    completion(.success(Data())) // Return empty data success
//                    return
//                } else {
//                    completion(.failure(.noData))
//                    return
//                }
//            }
//
//            // 5. Success - return the data
//            completion(.success(receivedData))
//        }
//        task.resume() // Start the network request
//    }
//}
