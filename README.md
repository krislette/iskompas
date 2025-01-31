<a id="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/krislette/iskompas">
    <img src="https://github.com/user-attachments/assets/b94e5ac8-0e8d-4931-a834-6109b861cd6b" alt="Logo" width="140" height="140">
  </a>

  <h1 align="center">Iskompas</h1>
  <p align="center">
    Find your way, the isko way
    <br />
    <a href="https://drive.google.com/file/d/1JgwW8XNOogMiq1dx4NPJ74zv5r1D4Deo/view?usp=sharing"><strong>Explore the paper »</strong></a>
    <br />
    <br />
    <a href="#demo">View Demo</a>
    ·
    <a href="https://github.com/krislette/iskompas/issues">Report Bug</a>
    ·
    <a href="https://github.com/krislette/iskompas/issues">Request Feature</a>
  </p>
</div>

<!-- PROJECT DEMO -->
## Demo


<!-- ABOUT THE PROJECT -->
## About The Project

Iskompas is a navigation app built specifically for the PUP Main Campus. Offering real-time directions and campus-specific information, Iskompas will make it easy for students and visitors to find their way to buildings, offices, and favorite spots. This app will be accessible to all, ensuring that everyone in the PUP community can take full advantage of its features. Our goal is to make campus navigation smoother and more intuitive, bridging physical spaces with digital guidance to support every Iskolar ng Bayan on their journey.

<!-- TABLE OF CONTENTS -->
## Table Of Contents
<ol>
  <li>
    <a href="#about-the-project">About The Project</a>
    <ul>
      <li><a href="#table-of-contents">Table Of Contents</a></li>
      <li><a href="#features">Features</a></li>
      <li><a href="#technologies">Technologies Used</a></li>
    </ul>
  </li>
  <li>
    <a href="#application-snapshots">Application Snapshots</a>
  </li>
  <li>
    <a href="#installation">Installation</a>
    <ul>
      <li><a href="#prerequisites">Prerequisites</a></li>
    </ul>
  </li>
  <li>
    <a href="#run">Run</a>
  </li>
  <li>
    <a href="#contributors">Contributors</a>
  </li>
  <li>
    <a href="#license">License</a>
  </li>
</ol> 

## Features

Iskompas is a campus navigation app specifically designed for the Polytechnic University of the Philippines - Mabini Campus. It provides real-time directions and location-based services to help students and visitors easily navigate the campus.

### Core Features

- 🗺️ **Interactive Map Navigation**
  - Displays a map of the PUP Mabini Campus.
  - Provides real-time GPS tracking for exterior navigation.
  - Shows a path line from the user’s current location to a selected destination.

- 📌 **Facilities List View**
  - Lists all important buildings, areas, offices, and services within the campus.
  - Displays facility descriptions, locations, and images.
  - Offers a floor plan for the Main Academic Building to assist with interior navigation.

- ⭐ **Bookmark Locations**
  - Allows users to save frequently visited or important locations.
  - Saves the navigation path for quick reference.
  - Provides a dedicated Saved Locations page for easy access.

- 🔍 **Search & Filter**
  - Enables users to search for specific facilities by name.
  - Incorporates filters to display specific types of facilities (e.g., offices, bathrooms, sports areas).
  
- 📍 **Real-time Location Tracking**
  - Uses GPS to show the user's current location on the map.
  - Updates in real-time as the user moves around the campus.

- 🏫 **Main Academic Building Floor Plan**
  - Provides a detailed floor plan for interior navigation of the main building.

- 🛠 **Offline Support for Saved Locations**
  - Users can access previously saved locations without an internet connection.
  - Local storage ensures bookmarked locations remain available.

- ⚠ **Error Handling & Reporting**
  - Displays clear notifications for input errors, system failures, permission denials, storage issues, and network errors.
  - Suggests solutions or alternative actions when errors occur.

<!-- TECHNOLOGIES USED -->
## Technologies

Iskompas utilizes a variety of technologies to ensure smooth and efficient operation:

- **[Mapbox](https://www.mapbox.com/)**: Provides interactive maps and location-based services for navigation.
- **[Flutter](https://flutter.dev/)**: A UI toolkit for building natively compiled mobile applications.
- **[Dart](https://dart.dev/)**: The programming language used for Flutter development.
- **[Figma](https://www.figma.com/)**: Designed using wireframing and prototyping tools like Figma.

These technologies enable Iskompas to provide an intuitive and efficient campus navigation experience. 

<!-- APPLICATION SNAPSHOTS -->
## Application Snapshots

<!-- INSTALLATION -->
## Installation
### Prerequisites

Before running the application, ensure you have the following installed on your system:

- **[Flutter](https://flutter.dev/docs/get-started/install)** (Latest stable version)
- **[Dart](https://dart.dev/get-dart)** (Included with Flutter)
- **[Android Studio](https://developer.android.com/studio)** (For Android development)
- **[Android SDK](https://developer.android.com/studio/releases/sdk-tools)** (Installed via Android Studio)
- **Device Emulator** (or a physical device with USB debugging enabled)

#### Setup
1. Clone the repository:
```
git clone https://github.com/yourusername/your-repo.git
```
2. Navigate to the project directory:
```
cd your-project-folder
```
3. Install dependencies:
```
flutter pub get
```

<!-- HOW TO RUN THE PROGRAM -->
##  Run
To run the application, follow these steps:

1. Start an emulator (or connect a physical device):
```
flutter devices
```
2. Run the app:
```
flutter run
```
3. If using Android Studio, open the project and click on Run > Run 'main.dart'.

<!-- Contributor's Table -->
## Contributors
  <table style="width: 100%; text-align: center;">
    <thead>
      <tr>
        <th>Name</th>
        <th>Avatar</th>
        <th>GitHub</th>
        <th>Contributions</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Acelle Krislette Rosales</td>
        <td><img src="https://github.com/user-attachments/assets/7594b3dd-67b6-4e8b-9337-6282f9040d72" alt="" style="border-radius: 50%; width: 50px;"></td>
        <td><a href="https://github.com/krislette">krislette</a></td>
        <td><b>Lead Developer</b>, <b>Fullstack Developer</b>: Acelle is responsible for overseeing the entire code production process. She created and set up the repository environment
          with a well-structured development workflow. She optimized the facilities page by implementing a search widget, enabling GPS location fetching, and preloading map data on the main interface. 
          Furthermore, she filtered annotations with pop-ups, developed turn-by-turn navigation, and enhanced map features, including pathfinding and theming. 
          She also implemented a functional search button for the map and made various optimizations. Acelle 
          contributed by adding nodes and serves as the main code reviewer for the application, ensuring code quality and consistency.
        </td>
      </tr>
      <tr>
        <td>Regina Bonifacio</td>
        <td><img src="https://github.com/user-attachments/assets/22c18520-6053-4909-afda-bc1d0e9355ff" alt="" style="border-radius: 50%; width: 50px;"></td>
        <td><a href="https://github.com/feiryrej">feiryrej</a></td>
        <td><b>Frontend Developer</b>, <b>UI/UX Designer</b>: Regina is responsible for designing the initial UI of the application, ensuring a visually appealing and functional user experience. 
          She developed the facility's page, implementing both the search functionality and floor plan integration. She also integrated the carousel feature on the save page and implemented 
          a component-based search bar across all pages. She also designed and developed the navbar, added nodes, and assembled the necessary data for the application. 
          As the frontend developer, Regina oversees the code structure and ensures the application's overall appearance aligns with the design vision.</td>
      </tr>
      <tr>
        <td>Duane Kyros Marzan</td>
        <td><img src="https://github.com/user-attachments/assets/6ccefe73-31fd-45c4-92ab-58ebd24191f0" alt="" style="border-radius: 50%; width: 50px;"></td>
        <td><a href="https://github.com/kyrariii">kyrariii</a></td>
        <td><b>UI/UX Designer</b>, <b>Data Gatherer</b>: Kyros is responsible for adding nodes throughout the campus map in Mapbox, collecting photos of facilities, and designing floor plans 
          for the main building. He also configured the text animation for the splash screen, assisted in designing the app’s wireframe, and designed the pin icons for facility types.
        </td>
      </tr>
      <tr>
        <td>Syruz Ken Domingo</td>
        <td><img src="https://github.com/user-attachments/assets/4dd666cf-b96d-4d92-bebf-9ea4efcd94ee" alt="" style="border-radius: 50%; width: 50px;"></td>
        <td><a href="https://github.com/sykeruzn">sykeruzn</a></td>
        <td><b>Project Manager</b>, <b>Data Gatherer</b>: Syke is responsible for adding thousands of nodes to the campus map in Mapbox, collecting and compiling facility photos and information, 
          and designing the floor plans of the main building. Additionally, he configured the compass logo animation for the splash screen and 
          finalized the functional specifications document by completing its content and proofreading for accuracy.
        </td>
      </tr>
    </tbody>
  </table>
</section>

## License

Distributed under the [MIT](https://choosealicense.com/licenses/mit/) License. See [LICENSE](LICENSE) for more information.

<p align="right">[<a href="#readme-top">Back to top</a>]</p>
