// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum About {
    /// Hey, thanks for using Friendly Competitions! I hope you're enjoying my app. Feel free to provide feedback below or reach out to me by visiting my website.
    /// 
    /// Evan
    internal static let hey = L10n.tr("Localizable", "About.hey", fallback: "Hey, thanks for using Friendly Competitions! I hope you're enjoying my app. Feel free to provide feedback below or reach out to me by visiting my website.\n\nEvan")
    /// Made with ❤️ in Toronto, Canada
    internal static let madeWithLove = L10n.tr("Localizable", "About.madeWithLove", fallback: "Made with ❤️ in Toronto, Canada")
    /// About
    internal static let title = L10n.tr("Localizable", "About.title", fallback: "About")
    internal enum App {
      /// by Evan Cooper
      internal static let authoredBy = L10n.tr("Localizable", "About.App.authoredBy", fallback: "by Evan Cooper")
      /// Code
      internal static let code = L10n.tr("Localizable", "About.App.code", fallback: "Code")
      /// Feature Request
      internal static let featureRequest = L10n.tr("Localizable", "About.App.featureRequest", fallback: "Feature Request")
      /// Did you know this app is completely open source? Tap above to find out more.
      internal static let openSource = L10n.tr("Localizable", "About.App.openSource", fallback: "Did you know this app is completely open source? Tap above to find out more.")
      /// Privacy Policy
      internal static let privacyPolicy = L10n.tr("Localizable", "About.App.privacyPolicy", fallback: "Privacy Policy")
      /// Rate
      internal static let rate = L10n.tr("Localizable", "About.App.rate", fallback: "Rate")
      /// Report an Issue
      internal static let reportIssue = L10n.tr("Localizable", "About.App.reportIssue", fallback: "Report an Issue")
      /// The App
      internal static let title = L10n.tr("Localizable", "About.App.title", fallback: "The App")
      /// Version
      internal static let version = L10n.tr("Localizable", "About.App.version", fallback: "Version")
    }
    internal enum Developer {
      /// My Website
      internal static let website = L10n.tr("Localizable", "About.Developer.website", fallback: "My Website")
    }
  }
  internal enum ActivitySummaryInfo {
    /// Exercise
    internal static let exercise = L10n.tr("Localizable", "ActivitySummaryInfo.exercise", fallback: "Exercise")
    /// Move
    internal static let move = L10n.tr("Localizable", "ActivitySummaryInfo.move", fallback: "Move")
    /// Stand
    internal static let stand = L10n.tr("Localizable", "ActivitySummaryInfo.stand", fallback: "Stand")
    internal enum MissingPermissions {
      /// Request
      internal static let cta = L10n.tr("Localizable", "ActivitySummaryInfo.MissingPermissions.cta", fallback: "Request")
      /// Missing HealthKit permissions for reading rings
      internal static let message = L10n.tr("Localizable", "ActivitySummaryInfo.MissingPermissions.message", fallback: "Missing HealthKit permissions for reading rings")
    }
    internal enum NotFound {
      /// Check
      internal static let cta = L10n.tr("Localizable", "ActivitySummaryInfo.NotFound.cta", fallback: "Check")
      /// Couldn't find your rings for today. Check HealthKit permissions.
      internal static let message = L10n.tr("Localizable", "ActivitySummaryInfo.NotFound.message", fallback: "Couldn't find your rings for today. Check HealthKit permissions.")
    }
    internal enum Value {
      /// -
      internal static let empty = L10n.tr("Localizable", "ActivitySummaryInfo.Value.empty", fallback: "-")
    }
  }
  internal enum AuthenticationError {
    /// Missing email
    internal static let missingEmail = L10n.tr("Localizable", "AuthenticationError.missingEmail", fallback: "Missing email")
    /// Passwords don't match
    internal static let passwordMatch = L10n.tr("Localizable", "AuthenticationError.passwordMatch", fallback: "Passwords don't match")
  }
  internal enum Banner {
    internal enum HealthKitDataMissing {
      /// Check
      internal static let cta = L10n.tr("Localizable", "Banner.HealthKitDataMissing.cta", fallback: "Check")
      /// Can't find any data. Check HealthKit permissions.
      internal static let message = L10n.tr("Localizable", "Banner.HealthKitDataMissing.message", fallback: "Can't find any data. Check HealthKit permissions.")
    }
    internal enum HealthKitPermissionsMissing {
      /// Request
      internal static let cta = L10n.tr("Localizable", "Banner.HealthKitPermissionsMissing.cta", fallback: "Request")
      /// Missing HealthKit permissions to count your score.
      internal static let message = L10n.tr("Localizable", "Banner.HealthKitPermissionsMissing.message", fallback: "Missing HealthKit permissions to count your score.")
    }
    internal enum NotificationPermissionsDenied {
      /// Change
      internal static let cta = L10n.tr("Localizable", "Banner.NotificationPermissionsDenied.cta", fallback: "Change")
      /// Notification permissions denied. You won't be updated.
      internal static let message = L10n.tr("Localizable", "Banner.NotificationPermissionsDenied.message", fallback: "Notification permissions denied. You won't be updated.")
    }
    internal enum NotificationPermissionsMissing {
      /// Request
      internal static let cta = L10n.tr("Localizable", "Banner.NotificationPermissionsMissing.cta", fallback: "Request")
      /// Missing Notification permissions to keep you updated.
      internal static let message = L10n.tr("Localizable", "Banner.NotificationPermissionsMissing.message", fallback: "Missing Notification permissions to keep you updated.")
    }
  }
  internal enum Competition {
    internal enum Action {
      internal enum AcceptInvite {
        /// Accept invite
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.AcceptInvite.buttonTitle", fallback: "Accept invite")
      }
      internal enum DeclineInvite {
        /// Decline invite
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.DeclineInvite.buttonTitle", fallback: "Decline invite")
      }
      internal enum Delete {
        /// Delete competition
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.Delete.buttonTitle", fallback: "Delete competition")
        /// Are you sure you want to delete the competition?
        internal static let confirmationTitle = L10n.tr("Localizable", "Competition.Action.Delete.confirmationTitle", fallback: "Are you sure you want to delete the competition?")
      }
      internal enum Edit {
        /// Edit
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.Edit.buttonTitle", fallback: "Edit")
      }
      internal enum Invite {
        /// Invite a friend
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.Invite.buttonTitle", fallback: "Invite a friend")
      }
      internal enum Join {
        /// Join competition
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.Join.buttonTitle", fallback: "Join competition")
      }
      internal enum Leave {
        /// Leave competition
        internal static let buttonTitle = L10n.tr("Localizable", "Competition.Action.Leave.buttonTitle", fallback: "Leave competition")
        /// Are you sure you want to leave?
        internal static let confirmationTitle = L10n.tr("Localizable", "Competition.Action.Leave.confirmationTitle", fallback: "Are you sure you want to leave?")
      }
    }
    internal enum Details {
      /// Ended
      internal static let ended = L10n.tr("Localizable", "Competition.Details.ended", fallback: "Ended")
      /// Ends
      internal static let ends = L10n.tr("Localizable", "Competition.Details.ends", fallback: "Ends")
      /// Repeats
      internal static let repeats = L10n.tr("Localizable", "Competition.Details.repeats", fallback: "Repeats")
      /// Scoring model
      internal static let scoringModel = L10n.tr("Localizable", "Competition.Details.scoringModel", fallback: "Scoring model")
      /// Started
      internal static let started = L10n.tr("Localizable", "Competition.Details.started", fallback: "Started")
      /// Starts
      internal static let starts = L10n.tr("Localizable", "Competition.Details.starts", fallback: "Starts")
    }
    internal enum Edit {
      /// Ends
      internal static let ends = L10n.tr("Localizable", "Competition.Edit.ends", fallback: "Ends")
      /// Learn more
      internal static let learnMore = L10n.tr("Localizable", "Competition.Edit.learnMore", fallback: "Learn more")
      /// Name
      internal static let name = L10n.tr("Localizable", "Competition.Edit.name", fallback: "Name")
      /// Public
      internal static let `public` = L10n.tr("Localizable", "Competition.Edit.public", fallback: "Public")
      /// Repeats
      internal static let repeats = L10n.tr("Localizable", "Competition.Edit.repeats", fallback: "Repeats")
      /// Scoring
      internal static let scoringModel = L10n.tr("Localizable", "Competition.Edit.scoringModel", fallback: "Scoring")
      /// Starts
      internal static let starts = L10n.tr("Localizable", "Competition.Edit.starts", fallback: "Starts")
      /// Details
      internal static let title = L10n.tr("Localizable", "Competition.Edit.title", fallback: "Details")
      /// Workout metrics
      internal static let workoutMetrics = L10n.tr("Localizable", "Competition.Edit.workoutMetrics", fallback: "Workout metrics")
      /// Workout Type
      internal static let workoutType = L10n.tr("Localizable", "Competition.Edit.workoutType", fallback: "Workout Type")
      internal enum Public {
        /// Heads up! Anyone can join public competitions from the explore page.
        internal static let disclaimer = L10n.tr("Localizable", "Competition.Edit.Public.disclaimer", fallback: "Heads up! Anyone can join public competitions from the explore page.")
      }
      internal enum Repeats {
        /// This competition will restart the next day after it ends.
        internal static let disclaimer = L10n.tr("Localizable", "Competition.Edit.Repeats.disclaimer", fallback: "This competition will restart the next day after it ends.")
      }
    }
    internal enum Results {
      /// Results
      internal static let results = L10n.tr("Localizable", "Competition.Results.results", fallback: "Results")
    }
    internal enum ScoringModel {
      internal enum ActivityRingCloseCount {
        /// Every ring (move, exercise, stand) closed gains 1 point.
        internal static let description = L10n.tr("Localizable", "Competition.ScoringModel.ActivityRingCloseCount.description", fallback: "Every ring (move, exercise, stand) closed gains 1 point.")
        /// Ring Close Count
        internal static let displayName = L10n.tr("Localizable", "Competition.ScoringModel.ActivityRingCloseCount.displayName", fallback: "Ring Close Count")
      }
      internal enum PercentOfGoals {
        /// Every percent of an activity ring filled gains 1 point.
        internal static let description = L10n.tr("Localizable", "Competition.ScoringModel.PercentOfGoals.description", fallback: "Every percent of an activity ring filled gains 1 point.")
        /// Percent of Goals
        internal static let displayName = L10n.tr("Localizable", "Competition.ScoringModel.PercentOfGoals.displayName", fallback: "Percent of Goals")
      }
      internal enum RawNumbers {
        /// Every calorie, minute and hour gains 1 point. No daily max.
        internal static let description = L10n.tr("Localizable", "Competition.ScoringModel.RawNumbers.description", fallback: "Every calorie, minute and hour gains 1 point. No daily max.")
        /// Raw numbers
        internal static let displayName = L10n.tr("Localizable", "Competition.ScoringModel.RawNumbers.displayName", fallback: "Raw numbers")
      }
      internal enum Steps {
        /// Every step gains 1 point.
        internal static let description = L10n.tr("Localizable", "Competition.ScoringModel.Steps.description", fallback: "Every step gains 1 point.")
        /// Step Count
        internal static let displayName = L10n.tr("Localizable", "Competition.ScoringModel.Steps.displayName", fallback: "Step Count")
      }
      internal enum Workout {
        /// Only activity during certain workout types will count towards points.
        internal static let description = L10n.tr("Localizable", "Competition.ScoringModel.Workout.description", fallback: "Only activity during certain workout types will count towards points.")
        /// Only %@ workouts will count towards points.
        internal static func descriptionWithType(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Competition.ScoringModel.Workout.descriptionWithType", String(describing: p1), fallback: "Only %@ workouts will count towards points.")
        }
        /// Workout
        internal static let displayName = L10n.tr("Localizable", "Competition.ScoringModel.Workout.displayName", fallback: "Workout")
        /// %@ workout
        internal static func displayNameWithType(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Competition.ScoringModel.Workout.displayNameWithType", String(describing: p1), fallback: "%@ workout")
        }
      }
    }
    internal enum Standings {
      /// Nothing here, yet.
      internal static let empty = L10n.tr("Localizable", "Competition.Standings.empty", fallback: "Nothing here, yet.")
      /// Show more
      internal static let showMore = L10n.tr("Localizable", "Competition.Standings.showMore", fallback: "Show more")
      /// Standings
      internal static let title = L10n.tr("Localizable", "Competition.Standings.title", fallback: "Standings")
    }
  }
  internal enum Confirmation {
    /// Are you sure?
    internal static let areYouSure = L10n.tr("Localizable", "Confirmation.areYouSure", fallback: "Are you sure?")
    /// Are you sure? This cannot be undone.
    internal static let areYouSureCannotBeUndone = L10n.tr("Localizable", "Confirmation.areYouSureCannotBeUndone", fallback: "Are you sure? This cannot be undone.")
  }
  internal enum CreateAccount {
    /// Sign up with Apple
    internal static let apple = L10n.tr("Localizable", "CreateAccount.apple", fallback: "Sign up with Apple")
    /// Create an account so that you can receive notifications and create competitions, and more.
    /// 
    /// Don't worry, all of your data will be migrated to your new account.
    internal static let desctiption = L10n.tr("Localizable", "CreateAccount.desctiption", fallback: "Create an account so that you can receive notifications and create competitions, and more.\n\nDon't worry, all of your data will be migrated to your new account.")
    /// Sign up with email
    internal static let email = L10n.tr("Localizable", "CreateAccount.email", fallback: "Sign up with email")
    /// More options
    internal static let moreOptions = L10n.tr("Localizable", "CreateAccount.moreOptions", fallback: "More options")
    /// Create account
    internal static let title = L10n.tr("Localizable", "CreateAccount.title", fallback: "Create account")
  }
  internal enum DeepLink {
    internal enum Competition {
      /// Compete against me in Friendly Competitions!
      internal static let title = L10n.tr("Localizable", "DeepLink.Competition.title", fallback: "Compete against me in Friendly Competitions!")
    }
    internal enum User {
      /// Add me in Friendly Competitions!
      internal static let title = L10n.tr("Localizable", "DeepLink.User.title", fallback: "Add me in Friendly Competitions!")
    }
  }
  internal enum Developer {
    /// Developer
    internal static let title = L10n.tr("Localizable", "Developer.title", fallback: "Developer")
    internal enum Environment {
      /// Environment type
      internal static let environmentType = L10n.tr("Localizable", "Developer.Environment.environmentType", fallback: "Environment type")
      /// Firebase Environment
      internal static let title = L10n.tr("Localizable", "Developer.Environment.title", fallback: "Firebase Environment")
      internal enum Emulation {
        /// Emulation destination
        internal static let destination = L10n.tr("Localizable", "Developer.Environment.Emulation.destination", fallback: "Emulation destination")
        /// Emulation type
        internal static let type = L10n.tr("Localizable", "Developer.Environment.Emulation.type", fallback: "Emulation type")
      }
    }
  }
  internal enum EmailSignIn {
    /// Email
    internal static let email = L10n.tr("Localizable", "EmailSignIn.email", fallback: "Email")
    /// Forgot?
    internal static let forgot = L10n.tr("Localizable", "EmailSignIn.forgot", fallback: "Forgot?")
    /// Have an account?
    internal static let haveAnAccount = L10n.tr("Localizable", "EmailSignIn.haveAnAccount", fallback: "Have an account?")
    /// Name
    internal static let name = L10n.tr("Localizable", "EmailSignIn.name", fallback: "Name")
    /// New to %@?
    internal static func new(_ p1: Any) -> String {
      return L10n.tr("Localizable", "EmailSignIn.new", String(describing: p1), fallback: "New to %@?")
    }
    /// Password
    internal static let password = L10n.tr("Localizable", "EmailSignIn.password", fallback: "Password")
    /// Confirm password
    internal static let passwordConfirmation = L10n.tr("Localizable", "EmailSignIn.passwordConfirmation", fallback: "Confirm password")
    /// Sign in
    internal static let signIn = L10n.tr("Localizable", "EmailSignIn.signIn", fallback: "Sign in")
    /// Sign up
    internal static let signUp = L10n.tr("Localizable", "EmailSignIn.signUp", fallback: "Sign up")
  }
  internal enum Explore {
    /// Explore
    internal static let title = L10n.tr("Localizable", "Explore.title", fallback: "Explore")
    internal enum Search {
      /// Nothing here
      internal static let nothingHere = L10n.tr("Localizable", "Explore.Search.nothingHere", fallback: "Nothing here")
    }
  }
  internal enum Generics {
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "Generics.cancel", fallback: "Cancel")
    /// Continue
    internal static let `continue` = L10n.tr("Localizable", "Generics.continue", fallback: "Continue")
    /// No
    internal static let no = L10n.tr("Localizable", "Generics.no", fallback: "No")
    /// Save
    internal static let save = L10n.tr("Localizable", "Generics.save", fallback: "Save")
    /// Yes
    internal static let yes = L10n.tr("Localizable", "Generics.yes", fallback: "Yes")
    internal enum Symbols {
      /// &
      internal static let apersand = L10n.tr("Localizable", "Generics.Symbols.apersand", fallback: "&")
    }
  }
  internal enum Home {
    internal enum Section {
      internal enum Activity {
        /// Have you worn your watch today? We can't find any activity summaries yet. If this is a mistake, please make sure that permissions are enabled in the Health app.
        internal static let missing = L10n.tr("Localizable", "Home.Section.Activity.missing", fallback: "Have you worn your watch today? We can't find any activity summaries yet. If this is a mistake, please make sure that permissions are enabled in the Health app.")
        /// Activity
        internal static let title = L10n.tr("Localizable", "Home.Section.Activity.title", fallback: "Activity")
      }
      internal enum Competitions {
        /// Start a competition against your friends!
        internal static let createPrompt = L10n.tr("Localizable", "Home.Section.Competitions.createPrompt", fallback: "Start a competition against your friends!")
        /// Competitions
        internal static let title = L10n.tr("Localizable", "Home.Section.Competitions.title", fallback: "Competitions")
      }
      internal enum Friends {
        /// Add friends to get started!
        internal static let addPrompt = L10n.tr("Localizable", "Home.Section.Friends.addPrompt", fallback: "Add friends to get started!")
        /// Invited
        internal static let invited = L10n.tr("Localizable", "Home.Section.Friends.invited", fallback: "Invited")
        /// Friends
        internal static let title = L10n.tr("Localizable", "Home.Section.Friends.title", fallback: "Friends")
      }
    }
  }
  internal enum InviteFriends {
    /// Accept
    internal static let accept = L10n.tr("Localizable", "InviteFriends.accept", fallback: "Accept")
    /// Having trouble?
    internal static let havingTrouble = L10n.tr("Localizable", "InviteFriends.havingTrouble", fallback: "Having trouble?")
    /// Invite
    internal static let invite = L10n.tr("Localizable", "InviteFriends.invite", fallback: "Invite")
    /// Invited
    internal static let invited = L10n.tr("Localizable", "InviteFriends.invited", fallback: "Invited")
    /// Send an invite link
    internal static let sendAnInviteLink = L10n.tr("Localizable", "InviteFriends.sendAnInviteLink", fallback: "Send an invite link")
    /// Invite friends
    internal static let title = L10n.tr("Localizable", "InviteFriends.title", fallback: "Invite friends")
  }
  internal enum ListItem {
    internal enum Email {
      /// Email
      internal static let description = L10n.tr("Localizable", "ListItem.Email.description", fallback: "Email")
    }
    internal enum Name {
      /// Name
      internal static let description = L10n.tr("Localizable", "ListItem.Name.description", fallback: "Name")
    }
  }
  internal enum NewCompetition {
    /// Create
    internal static let create = L10n.tr("Localizable", "NewCompetition.create", fallback: "Create")
    /// New Competition
    internal static let titile = L10n.tr("Localizable", "NewCompetition.titile", fallback: "New Competition")
    internal enum Disabled {
      /// Please invite at least 1 friend, or make the competition public
      internal static let inviteFriend = L10n.tr("Localizable", "NewCompetition.Disabled.inviteFriend", fallback: "Please invite at least 1 friend, or make the competition public")
      /// Please enter a name
      internal static let name = L10n.tr("Localizable", "NewCompetition.Disabled.name", fallback: "Please enter a name")
    }
    internal enum Friends {
      /// Add friends
      internal static let addFriends = L10n.tr("Localizable", "NewCompetition.Friends.addFriends", fallback: "Add friends")
      /// Nothing here, yet!
      internal static let nothingHere = L10n.tr("Localizable", "NewCompetition.Friends.nothingHere", fallback: "Nothing here, yet!")
      /// Invite friends
      internal static let title = L10n.tr("Localizable", "NewCompetition.Friends.title", fallback: "Invite friends")
    }
  }
  internal enum Permission {
    internal enum Health {
      /// So we can count score
      internal static let description = L10n.tr("Localizable", "Permission.Health.description", fallback: "So we can count score")
      /// Health
      internal static let title = L10n.tr("Localizable", "Permission.Health.title", fallback: "Health")
    }
    internal enum Notifications {
      /// So you can stay up to date
      internal static let desciption = L10n.tr("Localizable", "Permission.Notifications.desciption", fallback: "So you can stay up to date")
      /// Notifications
      internal static let titile = L10n.tr("Localizable", "Permission.Notifications.titile", fallback: "Notifications")
    }
    internal enum Status {
      /// Allow
      internal static let allow = L10n.tr("Localizable", "Permission.Status.allow", fallback: "Allow")
      /// Allowed
      internal static let allowed = L10n.tr("Localizable", "Permission.Status.allowed", fallback: "Allowed")
      /// Denied
      internal static let denied = L10n.tr("Localizable", "Permission.Status.denied", fallback: "Denied")
      /// Done
      internal static let done = L10n.tr("Localizable", "Permission.Status.done", fallback: "Done")
    }
  }
  internal enum Permissions {
    /// You can always change your responses in the settings app.
    internal static let footer = L10n.tr("Localizable", "Permissions.footer", fallback: "You can always change your responses in the settings app.")
    /// To get the best experience in Friendly Competitions, we need access to a few things.
    internal static let header = L10n.tr("Localizable", "Permissions.header", fallback: "To get the best experience in Friendly Competitions, we need access to a few things.")
    /// Permissions needed
    internal static let title = L10n.tr("Localizable", "Permissions.title", fallback: "Permissions needed")
  }
  internal enum Premium {
    internal enum Banner {
      /// Learn more
      internal static let learnMore = L10n.tr("Localizable", "Premium.Banner.learnMore", fallback: "Learn more")
      /// Get instant access to all of your competition results. The latest results for all competitions are always free.
      internal static let message = L10n.tr("Localizable", "Premium.Banner.message", fallback: "Get instant access to all of your competition results. The latest results for all competitions are always free.")
      /// Friendly Competitions Premium
      internal static let title = L10n.tr("Localizable", "Premium.Banner.title", fallback: "Friendly Competitions Premium")
    }
    internal enum Paywall {
      /// Privacy Policy
      internal static let pp = L10n.tr("Localizable", "Premium.Paywall.pp", fallback: "Privacy Policy")
      /// Restore Purchases
      internal static let restore = L10n.tr("Localizable", "Premium.Paywall.restore", fallback: "Restore Purchases")
      /// Terms of Service
      internal static let tos = L10n.tr("Localizable", "Premium.Paywall.tos", fallback: "Terms of Service")
    }
    internal enum Primer {
      /// Get instant access to all of your competition results. The latest results for all competitions are always free.
      internal static let message = L10n.tr("Localizable", "Premium.Primer.message", fallback: "Get instant access to all of your competition results. The latest results for all competitions are always free.")
      /// Preimum
      internal static let title = L10n.tr("Localizable", "Premium.Primer.title", fallback: "Preimum")
    }
    internal enum Purchase {
      /// Auto-renews. Cancel Anytime.
      internal static let autoRenews = L10n.tr("Localizable", "Premium.Purchase.autoRenews", fallback: "Auto-renews. Cancel Anytime.")
      /// Premium
      internal static let title = L10n.tr("Localizable", "Premium.Purchase.title", fallback: "Premium")
    }
  }
  internal enum Profile {
    /// Share invite link
    internal static let shareInviteLink = L10n.tr("Localizable", "Profile.shareInviteLink", fallback: "Share invite link")
    /// Profile
    internal static let title = L10n.tr("Localizable", "Profile.title", fallback: "Profile")
    internal enum Account {
      /// You are using an anonymous account. Some features will be disabled until you create a real account.
      internal static let anonymous = L10n.tr("Localizable", "Profile.Account.anonymous", fallback: "You are using an anonymous account. Some features will be disabled until you create a real account.")
      /// Create account
      internal static let createAccount = L10n.tr("Localizable", "Profile.Account.createAccount", fallback: "Create account")
      /// Delete account
      internal static let deleteAccount = L10n.tr("Localizable", "Profile.Account.deleteAccount", fallback: "Delete account")
      /// Sign out
      internal static let signOut = L10n.tr("Localizable", "Profile.Account.signOut", fallback: "Sign out")
      /// Account
      internal static let title = L10n.tr("Localizable", "Profile.Account.title", fallback: "Account")
    }
    internal enum Medals {
      /// Medals
      internal static let title = L10n.tr("Localizable", "Profile.Medals.title", fallback: "Medals")
    }
    internal enum Premium {
      /// Expires on %@
      internal static func expiresOn(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Profile.Premium.expiresOn", String(describing: p1), fallback: "Expires on %@")
      }
      /// Manage
      internal static let manage = L10n.tr("Localizable", "Profile.Premium.manage", fallback: "Manage")
      /// Renews on %@
      internal static func renewsOn(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Profile.Premium.renewsOn", String(describing: p1), fallback: "Renews on %@")
      }
      /// Friendly Competitions Premium
      internal static let title = L10n.tr("Localizable", "Profile.Premium.title", fallback: "Friendly Competitions Premium")
    }
    internal enum Privacy {
      /// Privacy
      internal static let title = L10n.tr("Localizable", "Profile.Privacy.title", fallback: "Privacy")
      internal enum HideName {
        /// Turn this off to hide your name in competitions. Your friends will still see your name.
        internal static let description = L10n.tr("Localizable", "Profile.Privacy.HideName.description", fallback: "Turn this off to hide your name in competitions. Your friends will still see your name.")
        /// Show name
        internal static let title = L10n.tr("Localizable", "Profile.Privacy.HideName.title", fallback: "Show name")
      }
      internal enum Searchable {
        /// Turn this off to prevent your account from showing up in search. Other people will not be able to add you as a friend.
        internal static let description = L10n.tr("Localizable", "Profile.Privacy.Searchable.description", fallback: "Turn this off to prevent your account from showing up in search. Other people will not be able to add you as a friend.")
        /// Searchable
        internal static let title = L10n.tr("Localizable", "Profile.Privacy.Searchable.title", fallback: "Searchable")
      }
    }
  }
  internal enum Results {
    /// You need Friendly Competitions Premium to see older results
    internal static let premiumRequred = L10n.tr("Localizable", "Results.premiumRequred", fallback: "You need Friendly Competitions Premium to see older results")
    /// Results
    internal static let title = L10n.tr("Localizable", "Results.title", fallback: "Results")
    internal enum ActivitySummaries {
      /// Rings
      internal static let title = L10n.tr("Localizable", "Results.ActivitySummaries.title", fallback: "Rings")
      internal enum BestDay {
        /// Your best day
        internal static let message = L10n.tr("Localizable", "Results.ActivitySummaries.BestDay.message", fallback: "Your best day")
      }
      internal enum RingsClosed {
        /// Rings closed
        internal static let message = L10n.tr("Localizable", "Results.ActivitySummaries.RingsClosed.message", fallback: "Rings closed")
      }
    }
    internal enum Points {
      /// Points
      internal static let title = L10n.tr("Localizable", "Results.Points.title", fallback: "Points")
    }
    internal enum Rank {
      /// Rank
      internal static let title = L10n.tr("Localizable", "Results.Rank.title", fallback: "Rank")
    }
    internal enum Standings {
      /// Standings
      internal static let title = L10n.tr("Localizable", "Results.Standings.title", fallback: "Standings")
    }
    internal enum StepCount {
      internal enum BestDay {
        /// Your best day
        internal static let message = L10n.tr("Localizable", "Results.StepCount.BestDay.message", fallback: "Your best day")
      }
    }
    internal enum Workouts {
      /// Workouts
      internal static let title = L10n.tr("Localizable", "Results.Workouts.title", fallback: "Workouts")
      internal enum BestDay {
        /// Your best day
        internal static let message = L10n.tr("Localizable", "Results.Workouts.BestDay.message", fallback: "Your best day")
      }
    }
  }
  internal enum Root {
    /// Explore
    internal static let explore = L10n.tr("Localizable", "Root.explore", fallback: "Explore")
    /// Home
    internal static let home = L10n.tr("Localizable", "Root.home", fallback: "Home")
  }
  internal enum SignIn {
    /// Sign in Anonymously
    internal static let anonymously = L10n.tr("Localizable", "SignIn.anonymously", fallback: "Sign in Anonymously")
    /// Sign in with Apple
    internal static let apple = L10n.tr("Localizable", "SignIn.apple", fallback: "Sign in with Apple")
    /// Sign in with Email
    internal static let email = L10n.tr("Localizable", "SignIn.email", fallback: "Sign in with Email")
  }
  internal enum User {
    internal enum Action {
      internal enum AcceptFriendRequest {
        /// Accept invite
        internal static let title = L10n.tr("Localizable", "User.Action.AcceptFriendRequest.title", fallback: "Accept invite")
      }
      internal enum DeclineFriendRequest {
        /// Decline invite
        internal static let title = L10n.tr("Localizable", "User.Action.DeclineFriendRequest.title", fallback: "Decline invite")
      }
      internal enum DeleteFriend {
        /// Remove friend
        internal static let title = L10n.tr("Localizable", "User.Action.DeleteFriend.title", fallback: "Remove friend")
      }
      internal enum RequestFriend {
        /// Add as friend
        internal static let title = L10n.tr("Localizable", "User.Action.RequestFriend.title", fallback: "Add as friend")
      }
    }
    internal enum Activity {
      /// Today's activity
      internal static let title = L10n.tr("Localizable", "User.Activity.title", fallback: "Today's activity")
    }
    internal enum Medals {
      /// Medals
      internal static let title = L10n.tr("Localizable", "User.Medals.title", fallback: "Medals")
    }
  }
  internal enum VerifyEmail {
    /// Follow the instructions sent to %@ to complete your account
    internal static func instructions(_ p1: Any) -> String {
      return L10n.tr("Localizable", "VerifyEmail.instructions", String(describing: p1), fallback: "Follow the instructions sent to %@ to complete your account")
    }
    /// Re-send email verification. Check your inbox!
    internal static let reSent = L10n.tr("Localizable", "VerifyEmail.reSent", fallback: "Re-send email verification. Check your inbox!")
    /// Send again
    internal static let sendAgain = L10n.tr("Localizable", "VerifyEmail.sendAgain", fallback: "Send again")
    /// Sign in
    internal static let signIn = L10n.tr("Localizable", "VerifyEmail.signIn", fallback: "Sign in")
    /// Verify your account
    internal static let title = L10n.tr("Localizable", "VerifyEmail.title", fallback: "Verify your account")
  }
  internal enum Welcome {
    /// Signing in anonymously will disable certain features like receiving notifications & creating compettions. However, you can always upgrade your account later.
    internal static let anonymousDisclaimer = L10n.tr("Localizable", "Welcome.anonymousDisclaimer", fallback: "Signing in anonymously will disable certain features like receiving notifications & creating compettions. However, you can always upgrade your account later.")
    /// Compete against friends in fitness.
    internal static let description = L10n.tr("Localizable", "Welcome.description", fallback: "Compete against friends in fitness.")
    /// Welcome to
    internal static let welcomeTo = L10n.tr("Localizable", "Welcome.welcomeTo", fallback: "Welcome to")
  }
  internal enum WorkoutMetric {
    internal enum Distance {
      /// Distance
      internal static let description = L10n.tr("Localizable", "WorkoutMetric.Distance.description", fallback: "Distance")
    }
    internal enum HeartRate {
      /// Heart rate
      internal static let description = L10n.tr("Localizable", "WorkoutMetric.HeartRate.description", fallback: "Heart rate")
    }
    internal enum Steps {
      /// Steps
      internal static let description = L10n.tr("Localizable", "WorkoutMetric.Steps.description", fallback: "Steps")
    }
  }
  internal enum WorkoutType {
    internal enum Cycling {
      /// Cycling
      internal static let description = L10n.tr("Localizable", "WorkoutType.Cycling.description", fallback: "Cycling")
    }
    internal enum Running {
      /// Running
      internal static let description = L10n.tr("Localizable", "WorkoutType.Running.description", fallback: "Running")
    }
    internal enum Swimming {
      /// Swimming
      internal static let description = L10n.tr("Localizable", "WorkoutType.Swimming.description", fallback: "Swimming")
    }
    internal enum Walking {
      /// Walking
      internal static let description = L10n.tr("Localizable", "WorkoutType.Walking.description", fallback: "Walking")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
