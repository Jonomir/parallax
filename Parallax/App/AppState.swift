import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var searchQuery: String = ""
    var activeWorkspaces: [Workspace] = []
    var repositories: [Repository] = []
    var selectedRepoForCreation: Repository? {
        didSet { focusSearch?() }
    }
    var errorMessage: String?
    var successMessage: String?
    var selectedIndex: Int = 0
    var wantsSettings = false
    var dismissPanel: (() -> Void)?
    var focusSearch: (() -> Void)?

    // MARK: - Private

    private var settings: AppSettings
    private var repoScanner: RepoScanner
    private var workspaceManager: WorkspaceManager
    private var workspaceRefreshService: WorkspaceRefreshService
    private let metadataStore: WorkspaceMetadataStore
    private let historyStore: HistoryStore

    init() {
        let loadResult = AppSettings.loadResult()
        let settings = loadResult.settings
        self.settings = settings
        let expandedWorkspaceRoot = settings.expandedWorkspaceRoot
        let metadataStore = WorkspaceMetadataStore()
        self.repoScanner = RepoScanner(rootPaths: settings.expandedRootPaths)
        self.workspaceManager = WorkspaceManager(basePath: expandedWorkspaceRoot, metadataStore: metadataStore)
        self.workspaceRefreshService = WorkspaceRefreshService(basePath: expandedWorkspaceRoot, metadataStore: metadataStore)
        self.metadataStore = metadataStore
        self.historyStore = HistoryStore()

        if let issue = loadResult.issue {
            switch issue {
            case .readFailed(let message):
                self.errorMessage = "Settings could not be read (\(message)). Loaded defaults."
            case .decodeFailed(let message):
                self.errorMessage = "Settings were invalid (\(message)). Loaded defaults and backed up the old file."
            }
        }
    }

    func reloadSettings() async {
        let newSettings = AppSettings.load()
        settings = newSettings
        let expandedWorkspaceRoot = newSettings.expandedWorkspaceRoot
        repoScanner = RepoScanner(rootPaths: newSettings.expandedRootPaths)
        workspaceManager = WorkspaceManager(basePath: expandedWorkspaceRoot, metadataStore: metadataStore)
        workspaceRefreshService = WorkspaceRefreshService(basePath: expandedWorkspaceRoot, metadataStore: metadataStore)
        await refresh()
    }

    // MARK: - Computed Properties

    var filteredWorkspaces: [(key: String, value: [Workspace])] {
        let filtered = searchQuery.isEmpty
            ? activeWorkspaces
            : activeWorkspaces.filter { $0.matches(query: searchQuery) }
        let grouped = Dictionary(grouping: filtered, by: \.repoName)
        return grouped.sorted { $0.key < $1.key }
    }

    var filteredRepos: [Repository] {
        let sorted = repositories.sorted { $0.frequency > $1.frequency }
        guard !searchQuery.isEmpty else { return sorted }
        return sorted.filter { $0.matches(query: searchQuery) }
    }

    var hasActiveWorkspaces: Bool {
        !filteredWorkspaces.isEmpty
    }

    enum SelectableItem {
        case workspace(Workspace)
        case repo(Repository)
    }

    var selectableItems: [SelectableItem] {
        var items: [SelectableItem] = []
        for (_, workspaces) in filteredWorkspaces {
            for ws in workspaces {
                items.append(.workspace(ws))
            }
        }
        for repo in filteredRepos {
            items.append(.repo(repo))
        }
        return items
    }

    var selectedItem: SelectableItem? {
        let items = selectableItems
        guard selectedIndex >= 0, selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    func moveSelection(by offset: Int) {
        let count = selectableItems.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + offset))
    }

    func clampSelection() {
        let count = selectableItems.count
        if count == 0 {
            selectedIndex = 0
        } else if selectedIndex >= count {
            selectedIndex = count - 1
        }
    }

    // MARK: - Actions

    func refresh() async {
        await refreshRepositories()
        await refreshWorkspaces()
    }

    func refreshWorkspaces() async {
        activeWorkspaces = await workspaceRefreshService.loadWorkspaces(repositories: repositories)
    }

    func refreshRepositories() async {
        var repos = await repoScanner.scan()
        let history = historyStore.load()
        for i in repos.indices {
            repos[i].frequency = history[repos[i].path] ?? 0
        }
        repositories = repos
    }

    func createWorkspace(for repo: Repository, taskName: String) async {
        do {
            historyStore.recordUsage(repoPath: repo.path)
            let workspace = try await workspaceManager.create(repo: repo, taskName: taskName)
            activeWorkspaces.append(workspace)
            do {
                try EditorLauncher.open(path: workspace.path, editor: settings.editor)
            } catch {
                errorMessage = "Workspace created, but failed to open editor: \(error.localizedDescription)"
            }
            await refreshRepositories()
        } catch {
            errorMessage = "Failed to create workspace: \(error.localizedDescription)"
        }
    }

    func deleteWorkspace(_ workspace: Workspace) async {
        do {
            try await workspaceManager.delete(workspace)
            activeWorkspaces.removeAll { $0.id == workspace.id }
        } catch {
            errorMessage = "Failed to delete workspace: \(error.localizedDescription)"
        }
    }

    func openWorkspace(_ workspace: Workspace) {
        do {
            try EditorLauncher.open(path: workspace.path, editor: settings.editor)
        } catch {
            errorMessage = "Failed to open workspace: \(error.localizedDescription)"
        }
    }

    func mergeBackWorkspace(_ workspace: Workspace) async {
        guard workspace.canMergeBack else {
            errorMessage = "Merge back unavailable: source repository could not be resolved for this workspace."
            return
        }

        do {
            try await workspaceManager.mergeBack(workspace)
            successMessage = "Pulled \(workspace.branchName ?? "branch") back to source repo"
            Task {
                do {
                    try await Task.sleep(for: .seconds(3))
                } catch {
                    return
                }
                successMessage = nil
            }
        } catch {
            errorMessage = "Failed to merge back: \(error.localizedDescription)"
        }
    }

}
