# Trip-Planner-App

Trip Planner is a Flutter-made app that is designed to help plan your vacations. This app uses the Open Street Maps tile server and Open Route Service API, which allows for direction-based navigation. Firebase backend services are working, which means that users can publish trip itineraries for others to see, using their Google account. I also integrated the MTA Subway API, where you can see real-time subway arrivals at stations nearest to you.

## Development

Want to beta-test this app? Follow this link to go to TestFlight on IOS: https://testflight.apple.com/join/f5PW402r

This repository is a lot of commits BEHIND. I will update it the next time I have the chance (I work on a seperate private repository to keep .gitignore files consistant).

## KNOWN BUGS:

- Trouble signing in with Apple Sign-In on certain devices. Please test using Google Sign-In services if the is the case.

- Itineraries mysteriously gets deleted when stored locally. Will investigate further.

- Name change functionality isn't working. UI is being uncoorporative. Will fix when I get the chance.

## To-Do list

- Beta Test App

- Add features --> A big problem is that users cannot delete online itineraries when it isn't stored locally anymore. 

- Publish to the App Store

## Example Screenshots

<p float="left">
<img width="206" alt="image" src="https://user-images.githubusercontent.com/107655677/211133193-3d52d947-a941-4c03-863d-3dfb82a53722.png">
<img width="205" alt="image" src="https://user-images.githubusercontent.com/107655677/211133231-669a35e2-a19d-4be9-b924-e791926cabbb.png">
<img width="205" alt="image" src="https://user-images.githubusercontent.com/107655677/212450796-94c18c4d-c082-4579-9147-97a7a34d7800.png">
<img width="205" alt="image" src="https://user-images.githubusercontent.com/107655677/212450822-0cf430d7-ab79-4b08-ac5a-e142615c7325.png">
</p>

## License
MIT License