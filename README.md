<div align="center">
  <h1><b>Bengaluru Civic Watch</b></h1>
  <p><i>Empowering Citizens, Transforming Bengaluru</i></p>
  <p>
    <img src="https://img.shields.io/github/last-commit/amruthkumartj/bengaluru-civic-watch" alt="Last Commit"/>
     <img src="https://img.shields.io/github/languages/top/amruthkumartj/bengaluru-civic-watch" alt="Top Language"/>
     <img src="https://img.shields.io/github/languages/count/amruthkumartj/bengaluru-civic-watch" alt="Languages"/>
     <img src="https://img.shields.io/github/stars/amruthkumartj/bengaluru-civic-watch?style=social" alt="Stars"/>
     <img src="https://img.shields.io/github/license/amruthkumartj/studentperformancetracking" alt="license"/>
  </p>
  <p>Built with:
    <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white"/>
    <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black"/>
    <img src="https://img.shields.io/badge/Firestore-FFA000?logo=google-cloud&logoColor=white"/>
    <img src="https://img.shields.io/badge/Node.js-339933?logo=node.js&logoColor=white"/>
    <img src="https://img.shields.io/badge/React-20232A?logo=react&logoColor=61DAFB"/>
  </p>
</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Overview

Bengaluru Civic Watch is a platform to report, track, and resolve civic issues in Bengaluru. It empowers citizens and authorities to collaborate for a better city.

---

## Features

- Report civic issues with location and images
- Real-time issue tracking and status updates
- Admin and authority dashboards
- Authentication and role-based access
- Analytics and reports

---

## Tech Stack

- **Frontend:** React.js (`civic-watch-admin`)
- **Backend:** Firebase Functions (`firebase-backend`)
- **Mobile:** Flutter (`FixMyOoru`)
- **Database:** Firestore

---

## Getting Started

### Prerequisites

- Node.js & npm
- Flutter SDK
- Firebase account

### Installation

```bash
# Clone the repo
git clone https://github.com/amruthkumartj/bengaluru-civic-watch.git
cd bengaluru-civic-watch

# Install frontend dependencies
cd civic-watch-admin
npm install

# For backend functions
cd ../firebase-backend/functions
npm install

# For Flutter app
cd ../../../FixMyOoru
flutter pub get
```

### Running Locally

- **Frontend:**
  ```bash
  cd civic-watch-admin
  npm start
  ```
- **Backend (Firebase Functions):**
  ```bash
  cd firebase-backend/functions
  firebase emulators:start --only functions
  ```
- **Flutter App:**
  ```bash
  cd FixMyOoru
  flutter run
  ```

---

## Screenshots :camera:

> _Add screenshots here_

---

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

---

## License

[MIT](LICENSE)

---

## Contact

- GitHub: [amruthkumartj](https://github.com/amruthkumartj)
- Email: amruthkumartj@gmail.com
