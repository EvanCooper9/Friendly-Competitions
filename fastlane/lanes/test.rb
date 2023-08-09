lane :test do
    run_tests(
        clean: !is_ci,
        scheme: "Friendly Competitions",
        device: "iPhone 14 Pro Max",
        xcargs: "CC=clang CPLUSPLUS=clang++ LD=clang LDPLUSPLUS=clang++",
        cloned_source_packages_path: "SourcePackages"
    )
end