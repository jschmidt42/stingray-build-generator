# Stingray Build Generator

This build generator allows you to create your own Stingray developer builds quickly.

## How to make your own build

### Step 1. Install prerequisites

-   Git client: <https://git-scm.com/>
    -   Git LFS 1.1.1 or greater (if you intend to run tests): <https://git-lfs.github.com/>
-   If using Visual Studio 2012:
    - Visual Studio 2012 with Blend: <https://www.microsoft.com/en-us/download/details.aspx?id=30682>
    - Update 5 for Visual Studio 2012: <https://www.microsoft.com/en-us/download/details.aspx?id=48708>
    - Visual Studio 2013 redistributables: <https://www.microsoft.com/en-us/download/details.aspx?id=40784>
-   If using Visual Studio 2015:
    - Visual Studio 2015 with Update 3 & Patch KB3165756: <https://www.visualstudio.com/downloads/#visual-studio-professional-2015-with-update-3>
    - Windows SDK 10.0.10586.0 or greater: <https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk>
    - Note that Windows 7 will sometimes fail to install the most recent Windows SDKs. If that happens to be the case then you can manually install version 10.0.10586.0 which can be found here: <https://developer.microsoft.com/en-us/windows/downloads/sdk-archive>.
- .NET 4.6.2 SDK: http://go.microsoft.com/fwlink/?LinkId=780617
-   Ruby 2.0 or later: <http://rubyinstaller.org>.
    -   Rubygems SSL fix (if needed): <http://guides.rubygems.org/ssl-certificate-update>
-   Node.js and NPM: <https://nodejs.org/en/>
-   DirectX End-User Runtimes (June 2010) : <http://www.microsoft.com/en-us/download/confirmation.aspx?id=8109>

### Step 2. Clone this repo

> git clone https://github.com/jschmidt42/stingray-build-generator.git

### Step 3. Locate your stingray source repo

The build generator will need to know where your Stingray source repo is located.

### Step 4. Run the build generator

> ruby generate-build.rb -r "G:\stingray" --zip --verbose

Replace `"G:\stingray"` with your Stingray source repo.

### Step 5. Wait...

The first time all the Stingray libs will be downloaded and this take might take 5-10 minutes. This should only occur once.

### Step 6. Build ready!

Once the process is completed, you should find your generated zip package under `./builds`.

By default it should be a file with the following pattern: `stingray_<commit#>_<date>.exe`, i.e. `stingray_e0fe34d0e_2017-06-08.exe`

### Step 7. Installation

When you launch the self-extracting packing you'll see something like this: ![image](https://user-images.githubusercontent.com/4054655/26930624-f3a46a10-4c2b-11e7-9c11-e1a01de1b31b.png)

Select the installation folder and click Install.

### Step 8. Installation finished

Once the installation is finished, a folder containing `stingray_editor.exe` should be opened for you. Simply execute the Stingray Editor executable to start working with this build.

