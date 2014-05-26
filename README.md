Syphon for Quartz Composer
===============

Syphon is a system for sending video between applications. You can use it to send high resolution and high frame rate video, 3D textures and synthesized content between Quartz Composer and other applications.

Syphon for Quartz Composer is packaged as a single plugin that contains 3 new patches:

* Syphon Server List - Outputs a structure of available Syphon Servers suitable for feeding to the Syphon Client patch. 

* Syphon Client - Brings video from other applications into Quartz Composer.

* Syphon Server - Publishes images (or the content of the 3D scene as rendered) from Quartz Composer, so that external applications which support Syphon can use them.

Licensing
===============

Syphon for Quartz Composer is published under a Simplified BSD license. See the included License.txt file.

Requirements
===============

Mac OS X 10.6.4 or greater
Xcode tools 3.2.3 of greater for Quartz Composer Editor
 
Installation
===============

Use the [latest released installer](https://github.com/Syphon/Quartz-Composer/releases) to install the plugin.

Instructions
===============

Using the Syphon Server patch - Syphon Server for QC is a consumer patch, which means it executes on a specific layer. You can patch the output of an image or video provider or  filter to the Syphon Servers image port, or alternatively set the "Source" input menu of the Syphon Server to "OpenGL Scene", which will capture any content rendered into the Viewer. When using "OpenGL Scene", be sure to set the Syphon Servers layer number to be higher than any content you wish to capture. Syphon Server respects alpha (transparency) for any input image of rendered scene.

Using the Syphon Client patch - Syphon Client for QC is a provider patch, which outputs an image from an existing Syphon Server. You can manually enter the Server Name (the human readable descriptive title of the frame source), and the Application Name, or alternatively use the Syphon Server List object, which outputs a structure which contains the available discovered Syphon Servers. 

Compositions can use any number of Syphon Clients and Servers, and users can load numerous compositions that leverage Syphon.

Supported Applications
===============

Quartz Composer compositions can be loaded by some 3rd party applications, so Syphon support should be easy to add to them.

Please see the support forums for an up to date list of working applications: http://forums.v002.info/forum.php?id=5

Changes since Public Beta 2
- When a Server is active, AppNap is prevented if the host app is hidden on MacOS Mavericks
- Fixes for various graphical issues affecting Servers

Changes since Public Beta 1
- If neither Server Name nor Application Name is provided to the Syphon Client plugin, it will match any available server.
- Fixes and improvements to the underlying Syphon framework.

Credits
===============

Syphon for Quartz Composer - Tom Butterworth (bangnoise) and Anton Marini (vade)

http://syphon.v002.info
