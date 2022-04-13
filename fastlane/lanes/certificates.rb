lane :certificates do
    if is_ci
        match(
            type: "development", 
            app_identifier: "com.evancooper.FriendlyCompetitions.debug",
            git_bearer_authorization: ENV["GITHUB_KEY"]
        )
        match(
            type: "appstore", 
            app_identifier: "com.evancooper.FriendlyCompetitions",
            git_bearer_authorization: ENV["GITHUB_TOKEN"]
        )
    else
        match(
            type: "development", 
            app_identifier: "com.evancooper.FriendlyCompetitions.debug"
        )
        match(
            type: "appstore", 
            app_identifier: "com.evancooper.FriendlyCompetitions"
        )
    end
end