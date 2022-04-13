lane :certificates do
    match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions.debug")
    match(type: "appstore", app_identifier: "com.evancooper.FriendlyCompetitions")
end