# Friendly Competitions

Compete against groups of friends in fitness. Just like Apple's fitness cometitions but support for multiple participants in a single competition.

 <p align="center">
    <img alt="sc1" src="fastlane/screenshots/en-CA/iPhone 11 Pro Max 1.png" width="24%">
    <img alt="sc2" src="fastlane/screenshots/en-CA/iPhone 11 Pro Max 2.png" width="24%">
    <img alt="sc3" src="fastlane/screenshots/en-CA/iPhone 11 Pro Max 3.png" width="24%">
    <img alt="sc3" src="fastlane/screenshots/en-CA/iPhone 11 Pro Max 4.png" width="24%">
</p>

# Setup for contributors
## Homebrew
Instal [homebrew](https://brew.sh) and run the following:
```shell
brew bundle
```
This command will need to be re-run everytime [Brewfile](Brewfile) changes (almost never)

## Firebase
Access to a Firebase project is required. You can create one for youself in the [firebase console](https://console.firebase.google.com). Follow the instructions to setup a project and download the `GoogleService-Info.plist`. You'll need to place it in one of the following directories, depending on the scheme that you plan to run:
- `Friendly Competitions/Firebase/Debug/`
- `Friendly Competitions/Firebase/Release/`

The app uses the following firebase services:

### [Authentication](https://firebase.google.com/docs/auth)
Manages user authentication. Users need to be signed in to access any & all features
- Apple
- Email

### [Firestore](https://firebase.google.com/docs/firestore)
Stores all user & competition data

### [Functions](https://firebase.google.com/docs/functions)
Sends notifications, computes competition scores, cleans up old data. 

Some setup is required for the functions to be available to the app: 
```
cd firebase/functions
npm install
npm run-script deploy
```
> Note: This firebase services requires the [Blaze plan](https://firebase.google.com/pricing). You can also explore [emulating functions](https://firebase.google.com/docs/functions/get-started#emulate-execution-of-your-functions) instead of upgrading to the Blaze plan, or disable it's usage in the iOS client.

### [Storage](https://firebase.google.com/docs/storage)
Stores images, nothing else for now