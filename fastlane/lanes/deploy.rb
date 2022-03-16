lane :deploy do
    setup_ci
    app_store_connect_api_key(
        key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
        issuer_id: ENV["APP_STORE_CONNECT_API_ISSUER_ID"],
        key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"],
        duration: 1200, # optional (maximum 1200)
        in_house: false # optional but may be required if using match/sigh
    ) if is_ci
    match(type: "appstore", readonly: true)
    build_app(
        scheme: "Friendly Competitions", 
        include_bitcode: true
    )
    upload_symbols_to_crashlytics(
        gsp_path: "Friendly Competitions/Firebase/Release/GoogleService-Info.plist",
        binary_path: "fastlane/scripts/upload-symbols"
    )
    latest_testflight_build_number
    upload_to_app_store(
        build_number: latest_testflight_build_number + 1,
        force: true,
        reject_if_possible: true
    )
end