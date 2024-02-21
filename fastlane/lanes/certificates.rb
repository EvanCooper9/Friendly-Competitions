lane :certificates do
    # development release identifier
    match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions")
    match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions.FriendlyCompetitionsWidgets")

    # development debug identifier
    match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions.debug")
    match(type: "development", app_identifier: "com.evancooper.FriendlyCompetitions.debug.FriendlyCompetitionsWidgets")
    
    # app store release identifier
    match(type: "appstore", app_identifier: "com.evancooper.FriendlyCompetitions")
    match(type: "appstore", app_identifier: "com.evancooper.FriendlyCompetitions.FriendlyCompetitionsWidgets")
end