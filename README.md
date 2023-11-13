# PlistUtil

Create and edit plists and other data formats on the command line through horrible abuse of the Swift Coding protocols.

## Examples

Create an empty plist dictionary:

```sh
plistutil create --format binary file.plist
```

Convert a plist into a swift dictionary literal:

```sh
plistutil convert --format swift --out-file dictionary.swift file.plist
```

Insert some data (base64-encoded) into a plist file in-place, several keys down:

```sh
plistutil insert --key TopLevelKey --key SecondLevelKey --key ThirdLevelKey --type data --value "bmV2ZXIgZ29ubmEgZ2l2ZSB5b3UgdXAgOykK"
```

Remove the first element of the array under a top-level key, and put it in a new file with a different format:
```sh
plistutil remove --key TopLevelKey --key '^' --out-file plist.bin --format binary plist.xml
```

Extract the last element of the top-level array, and put it in a new file with the same format (inferred from input file):
```sh
plistutil extract --key '$' --out-file inner.bin plist.bin
```

Pretty-print a plist:
```sh
plistutil print plist.xml
```

## Using this from a plugin

Declare the dependency as you would normally, and then list the product as a dependency of your plugin target:

```swift
let package = Package(
    name: "Library",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Library",
            targets: ["Library"]),
    ],
    dependencies: [
        .package(url: "https://github.com/protonjohn/plistutil", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "Library",
            plugins: [.plugin(name: "Plugin")]),
        .testTarget(
            name: "LibraryTests",
            dependencies: ["Library"]),
        .plugin(name: "Plugin",
                capability: .command(intent: .custom(verb: "export-plist",
                                                     description: "Plist modifier"),
                                     permissions: [.writeToPackageDirectory(reason: "To modify plists")]),
                dependencies: [.product(name: "plistutil", package: "PlistUtil")]),
        .plugin(name: "BuildPlugin",
                capability: .buildTool(),
                dependencies: [.product(name: "plistutil", package: "PlistUtil")])
    ]
)
```

Then you should be able to get the path to this utitily from the `PluginContext` object passed to your build tool:

```swift
@main
struct BuildPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {

        let plistPath = context.pluginWorkDirectory.appending(subpath: "dict.plist")
        let outputPath = context.pluginWorkDirectory.appending(subpath: "dict.swift")

        return [
            .buildCommand(displayName: "Embed plist",
                          executable: try context.tool(named: "plistutil").path,
                          arguments: [
                            "convert",
                            "--format",
                            "swift",
                            "-o",
                            outputPath.string,
                            plistPath.string,
                          ],
                          inputFiles: [plistPath],
                          outputFiles: [outputPath]),
        ]
    }
}
```

## Contributing

This package has tests, but there may be bugs in subtle corner cases. If you find one, feel free to send a pull request.
Make sure you add tests for any new functionality or fixes you address. Thank you :)
