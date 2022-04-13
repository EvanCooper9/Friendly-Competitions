lane :certificates do
    if is_ci
        match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions.debug", git_private_key: ENV["GIT_PRIVATE_KEY"])
        match(type: "appstore", app_identifier: "com.evancooper.FriendlyCompetitions", git_private_key: ENV["GIT_PRIVATE_KEY"])
    else
        match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions.debug")
        match(type: "appstore", app_identifier: "com.evancooper.FriendlyCompetitions")
    end
end