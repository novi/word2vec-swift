// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "word2vec-swift",
    targets: [
        Target(name: "Word2Vec", dependencies: ["CWord2Vec"]),
        Target(name: "CWord2Vec"),
    ]
)
