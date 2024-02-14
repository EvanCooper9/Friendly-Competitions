lane :test do
    run_tests(
        clean: false,
        scheme: "FriendlyCompetitions",
        device: "iPhone 14 Pro Max",
        xcargs: "CC=clang CPLUSPLUS=clang++ LD=clang LDPLUSPLUS=clang++",
    )
end