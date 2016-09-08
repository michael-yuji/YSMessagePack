import PackageDescription

let package = Package(
    name: "Example",
    dependencies: [.Package(url: "https://github.com/michael-yuji/YSMessagePack.git", versions: Version(0,0,0)..<Version(2,0,0))]
)
