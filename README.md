# KickRokuApp

## Overview
KickRokuApp is a simple Roku application designed to stream live content from Kick.com. This project aims to provide a sideloaded Roku channel that automatically plays Kick streams using `.m3u8` files, mimicking the functionality of VLC's network stream feature.

## Status
- **Under Development**: This project is actively being developed and is not yet fully functional.
- **Current State**: Not Working - The app is in an early stage, and streaming functionality is not yet operational. Issues are being addressed as part of ongoing development.

## Features
- Stream live Kick content (e.g., targeting streamers like Asmongold or Tectone).
- Automatic retrieval of `.m3u8` stream URLs.
- Basic playback using Roku's Video node.

## Installation
1. Enable Developer Mode on your Roku device:
   - Press Home x3, Up x2, Right, Left, Right, Left, Right on the remote.
   - Note the IP address and access `http://[Roku-IP]:8060`.
2. Download the project files from this repository.
3. Zip the project folder and upload it via the Roku developer portal.
4. Install and launch the channel to test (note: currently non-functional).

## Known Issues
- Streaming does not work as intended.
- Potential API or `.m3u8` URL retrieval problems.
- Limited error handling and user feedback.

## Future Plans
- Implement reliable stream playback.
- Add support for multiple streamers.
- Enhance user interface and error reporting.
- Optimize performance and add quality selection.

## Getting Help
- **Report Issues**: Use the [Issues](https://github.com/idyllize/KickRokuApp/issues) tab to report bugs or suggest features.
- **Contact**: For direct assistance, reach out via Discord (idyllize) or check the commit history for updates.

## License
This project is licensed under the [MIT License](LICENSE), allowing free use, modification, and distribution with proper attribution.

## Acknowledgments
- Built with guidance from the xAI Grok, Claude Sonnet 4.
- Utilizes the Kick API and Roku SceneGraph framework.

## Last Updated
08:33 PM EDT, June 10, 2025
