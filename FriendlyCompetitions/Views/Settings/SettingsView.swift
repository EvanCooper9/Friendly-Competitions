import Factory
import StoreKit
import SwiftUI
import SwiftUIX

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        List {

            VStack(alignment: .center) {
                ProfilePicture(imageData: $viewModel.profilePictureImageData)

                Text(viewModel.user.name)
                    .bold()
                    .font(.title)
                if let email = viewModel.user.email {
                    Text(email)
                        .font(.title3)
                }
            }
            .maxWidth(.infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if !viewModel.isAnonymousAccount {
                Section {
                    Button(L10n.Settings.inviteFriends, systemImage: .personCropCircleBadgePlus, action: viewModel.shareInviteLinkTapped)
                }

                privacy
            }

            account
            about
        }
        .confirmationDialog(
            L10n.Confirmation.areYouSureCannotBeUndone,
            isPresented: $viewModel.confirmationRequired,
            titleVisibility: .visible
        ) {
            Button(L10n.Generics.yes, role: .destructive, action: viewModel.confirmTapped)
            Button(L10n.Generics.cancel, role: .cancel) {}
        }
        .navigationTitle(L10n.Settings.title)
        .embeddedInNavigationView()
        .withLoadingOverlay(isLoading: viewModel.loading)
        .registerScreenView(name: L10n.Settings.title)
    }

    private var account: some View {
        Section {
            if viewModel.isAnonymousAccount {
                Button(L10n.Settings.Account.createAccount, systemImage: .personCropCircleBadgePlus, action: viewModel.signUpTapped)
                Button(L10n.Settings.Account.signOut, systemImage: .personCropCircleBadgeMinus, action: viewModel.signOutTapped)
            } else {
                Button(L10n.Settings.Account.signOut, systemImage: .personCropCircleBadgeMinus, action: viewModel.signOutTapped)
                Button(L10n.Settings.Account.deleteAccount, systemImage: .trash, action: viewModel.deleteAccountTapped)
                    .foregroundColor(.red)
            }
        } header: {
            Text(L10n.Settings.Account.title)
        } footer: {
            if viewModel.isAnonymousAccount {
                Text(L10n.Settings.Account.anonymous)
            }
        }
        .sheet(isPresented: $viewModel.showCreateAccount, content: CreateAccountView.init)
    }

    @ViewBuilder
    private var privacy: some View {
        Section {
            Toggle(L10n.Settings.Privacy.Searchable.title, isOn: $viewModel.user.searchable)
        } header: {
            Text(L10n.Settings.Privacy.title)
        } footer: {
            Text(L10n.Settings.Privacy.Searchable.description)
        }

        Section {
            Toggle(L10n.Settings.Privacy.HideName.title, isOn: $viewModel.user.showRealName)
        } footer: {
            Group {
                Text(L10n.Settings.Privacy.HideName.description) +
                Text(" Learn more")
                    .foregroundColor(.accentColor)
            }
            .onTapGesture(perform: viewModel.hideNameLearnMoreTapped)
        }
        .sheet(isPresented: $viewModel.showHideNameLearnMore) {
            HideNameLearnMoreView(showName: $viewModel.user.showRealName)
        }
    }

    @ViewBuilder
    private var about: some View {
        Section {
            Text(L10n.Settings.About.hey)
            Link(destination: .developer) {
                Label(L10n.Settings.About.Developer.website, systemImage: .globeAmericasFill)
            }
            Link(destination: .buyMeCoffee) {
                Label(L10n.Settings.About.Developer.buyCoffee, systemImage: .cupAndSaucerFill)
            }
        } header: {
            Text(L10n.Settings.About.Developer.title)
        } footer: {
            Text(L10n.Settings.About.madeWithLove)
                .font(.footnote)
        }

        Section {
            Button(L10n.Settings.About.App.rate, systemImage: .heartFill) {
                requestReview()
            }
            Link(destination: .privacyPolicy) {
                Label(L10n.Settings.About.App.privacyPolicy, systemImage: .handRaisedFill)
            }
            Link(destination: .featureRequest(with: viewModel.user.id)) {
                Label(L10n.Settings.About.App.featureRequest, systemImage: .lightbulbFill)
            }
            Link(destination: .bugReport(with: viewModel.user.id)) {
                Label(L10n.Settings.About.App.reportIssue, systemImage: .ladybugFill)
            }
            Link(destination: .gitHub) {
                Label(L10n.Settings.About.App.code, systemImage: .chevronLeftForwardslashChevronRight)
            }
        } header: {
            Text(L10n.Settings.About.App.title)
        } footer: {
            Text(L10n.Settings.About.App.version(Bundle.main.version))
                .font(.footnote)
                .monospaced()
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .setupMocks()

    }
}
#endif
