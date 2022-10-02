lane :deploy do
    setup_ci
    
    app_store_connect_api_key(
        key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
        issuer_id: ENV["APP_STORE_CONNECT_API_ISSUER_ID"],
        key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"],
        duration: 1200, # optional (maximum 1200)
        in_house: false # optional but may be required if using match/sigh
    ) if is_ci
    
    certificates

    # Current Version (via xcodeproj)
    current_version = get_version_number
    testflight_build = latest_testflight_build_number
    testflight_version = Actions.lane_context[SharedValues::LATEST_TESTFLIGHT_VERSION]
    new_build = testflight_version == current_version ? testflight_build + 1 : 1
    
    increment_build_number(
        build_number: new_build
    )

    build_app

    upload_to_testflight(
        notify_external_testers: false
    )

    upload_symbols_to_crashlytics(
        gsp_path: "Friendly Competitions/Firebase/Release/GoogleService-Info.plist",
        binary_path: "fastlane/scripts/upload-symbols"
    )

    upload_to_app_store(
        force: true,
        submit_for_review: true,
        precheck_include_in_app_purchases: false,
        submission_information: {
            add_id_info_uses_idfa: false
        },
        skip_binary_upload: true
    )
end