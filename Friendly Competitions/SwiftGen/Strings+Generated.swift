// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum About {
    internal enum App {
      /// by Evan Cooper
      internal static let authoredBy = L10n.tr("Localizable", "About.App.authoredBy", fallback: "by Evan Cooper")
      /// Feature Request
      internal static let featureRequest = L10n.tr("Localizable", "About.App.featureRequest", fallback: "Feature Request")
      /// Privacy Policy
      internal static let privacyPolicy = L10n.tr("Localizable", "About.App.privacyPolicy", fallback: "Privacy Policy")
      /// Rate
      internal static let rate = L10n.tr("Localizable", "About.App.rate", fallback: "Rate")
      /// Report an Issue
      internal static let reportIssue = L10n.tr("Localizable", "About.App.reportIssue", fallback: "Report an Issue")
      /// The App
      internal static let title = L10n.tr("Localizable", "About.App.title", fallback: "The App")
    }
    internal enum Developer {
      /// The Developer
      internal static let title = L10n.tr("Localizable", "About.Developer.title", fallback: "The Developer")
      /// Website
      internal static let website = L10n.tr("Localizable", "About.Developer.website", fallback: "Website")
    }
  }
  internal enum ActivitySummaryInfo {
    /// Exercise
    internal static let exercise = L10n.tr("Localizable", "ActivitySummaryInfo.exercise", fallback: "Exercise")
    /// Move
    internal static let move = L10n.tr("Localizable", "ActivitySummaryInfo.move", fallback: "Move")
    /// Stand
    internal static let stand = L10n.tr("Localizable", "ActivitySummaryInfo.stand", fallback: "Stand")
    internal enum Value {
      /// -
      internal static let empty = L10n.tr("Localizable", "ActivitySummaryInfo.Value.empty", fallback: "-")
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
      /// Name
      internal static let name = L10n.tr("Localizable", "Competition.Edit.name", fallback: "Name")
      /// Public
      internal static let `public` = L10n.tr("Localizable", "Competition.Edit.public", fallback: "Public")
      /// Repeats
      internal static let repeats = L10n.tr("Localizable", "Competition.Edit.repeats", fallback: "Repeats")
      /// Scoring Model
      internal static let scoringModel = L10n.tr("Localizable", "Competition.Edit.scoringModel", fallback: "Scoring Model")
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
  }
  internal enum Profile {
    /// Share invite link
    internal static let shareInviteLink = L10n.tr("Localizable", "Profile.shareInviteLink", fallback: "Share invite link")
    /// Profile
    internal static let title = L10n.tr("Localizable", "Profile.title", fallback: "Profile")
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
        /// Turn this off to hide your name in competitions that you join. You will still earn medals, and friends will still see your real name.
        internal static let description = L10n.tr("Localizable", "Profile.Privacy.HideName.description", fallback: "Turn this off to hide your name in competitions that you join. You will still earn medals, and friends will still see your real name.")
        /// Hide name
        internal static let title = L10n.tr("Localizable", "Profile.Privacy.HideName.title", fallback: "Hide name")
      }
      internal enum Searchable {
        /// Turn this off to prevent your account from showing up in search. Other people will not be able to add you as a friend.
        internal static let description = L10n.tr("Localizable", "Profile.Privacy.Searchable.description", fallback: "Turn this off to prevent your account from showing up in search. Other people will not be able to add you as a friend.")
        /// Searchable
        internal static let title = L10n.tr("Localizable", "Profile.Privacy.Searchable.title", fallback: "Searchable")
      }
    }
    internal enum Session {
      /// Delete account
      internal static let deleteAccount = L10n.tr("Localizable", "Profile.Session.deleteAccount", fallback: "Delete account")
      /// Sign out
      internal static let signOut = L10n.tr("Localizable", "Profile.Session.signOut", fallback: "Sign out")
      /// Session
      internal static let title = L10n.tr("Localizable", "Profile.Session.title", fallback: "Session")
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
    internal enum Workouts {
      /// Workouts
      internal static let title = L10n.tr("Localizable", "Results.Workouts.title", fallback: "Workouts")
      internal enum BestDay {
        /// Your best day
        internal static let message = L10n.tr("Localizable", "Results.Workouts.BestDay.message", fallback: "Your best day")
        /// Nothing here
        internal static let nothingHere = L10n.tr("Localizable", "Results.Workouts.BestDay.nothingHere", fallback: "Nothing here")
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
    /// Sign in with Apple
    internal static let apple = L10n.tr("Localizable", "SignIn.apple", fallback: "Sign in with Apple")
    /// Sign in with Email
    internal static let email = L10n.tr("Localizable", "SignIn.email", fallback: "Sign in with Email")
    /// Compete against groups of friends in fitness
    internal static let subTitle = L10n.tr("Localizable", "SignIn.subTitle", fallback: "Compete against groups of friends in fitness")
    /// Friendly Compeittions
    internal static let title = L10n.tr("Localizable", "SignIn.title", fallback: "Friendly Compeittions")
  }
  internal enum User {
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
    /// Send again
    internal static let sendAgain = L10n.tr("Localizable", "VerifyEmail.sendAgain", fallback: "Send again")
    /// Sign in
    internal static let signIn = L10n.tr("Localizable", "VerifyEmail.signIn", fallback: "Sign in")
    /// Verify your account
    internal static let title = L10n.tr("Localizable", "VerifyEmail.title", fallback: "Verify your account")
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