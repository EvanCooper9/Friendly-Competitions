lane :test do
    run_tests(
        clean: !is_ci,
        scheme: "Friendly Competitions",
        device: "iPhone 13 Pro Max",
        xcodebuild_command: "xcodebuild CC=clang CPLUSPLUS=clang++ LD=clang LDPLUSPLUS=clang++"
    )
end