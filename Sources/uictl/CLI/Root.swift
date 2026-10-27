import ArgumentParser

struct Root: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uictl",
        abstract: "Find, inspect, and drive running macOS GUI apps from the command line or from an MCP client.",
        discussion: """
        uictl locates running applications, lists and activates their windows, \
        screenshots them (optionally with a numbered element overlay), walks their \
        accessibility tree, clicks, types, sends key combos, waits for elements to \
        appear, runs OCR, samples pixel colors, and reads/writes the clipboard.

        A small daemon (auto-started on first use) holds Accessibility/Screen \
        Recording permission grants and the element-id cache across invocations — \
        see `uictl daemon status`.

        Every command prints one JSON object to stdout and exits 0 on success, \
        non-zero on failure.
        """,
        version: "0.1.0",
        subcommands: [
            DaemonCommand.self,
            PermissionsCommand.self,
            AppsCommand.self,
            DisplaysCommand.self,
            WindowsCommand.self,
            ActivateCommand.self,
            FocusCommand.self,
            ScreenshotCommand.self,
            ElementsCommand.self,
            ClickCommand.self,
            MoveCommand.self,
            ScrollCommand.self,
            TypeCommand.self,
            KeyCommand.self,
            WaitForCommand.self,
            OCRCommand.self,
            PixelCommand.self,
            ClipboardCommand.self,
            LogCommand.self,
            FeedbackCommand.self,
            MCPCommand.self,
        ]
    )

    @Flag(name: .customLong("libs-version"), help: "Print the libraries this build ships (name and version) and exit.")
    var libsVersion = false

    @Flag(name: .customLong("sbom"), help: "Print this build's CycloneDX JSON SBOM and exit.")
    var sbom = false

    func validate() throws {
        if libsVersion && sbom {
            throw ValidationError("--libs-version and --sbom are mutually exclusive.")
        }
    }

    func run() throws {
        if libsVersion {
            try emit(BuildInfo.libsVersion, flag: "--libs-version")
        } else if sbom {
            try emit(BuildInfo.sbom, flag: "--sbom")
        } else {
            throw CleanExit.helpRequest(Root.self)
        }
    }

    private func emit(_ text: String?, flag: String) throws {
        guard let text else {
            throw ValidationError("\(flag) is unavailable: this build was made without an SBOM (run `make sbom/install`, then `make build`).")
        }
        print(text)
    }
}
