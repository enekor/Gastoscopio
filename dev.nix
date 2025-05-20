nix
{ pkgs ? import <nixpkgs> {} }:

let
  android-sdk = pkgs.androidsdk.bindPkgs {
    buildToolsVersions = [ "30.0.3" ]; # Replace with your desired build tools version
    platformsVersions = [ "android-30" ]; # Replace with your desired Android platform version
    includeEmulator = true;
    includeSystemImages = true;
    cmdlineToolsVersion = "latest"; # or specify a version
    # Include platform tools like adb and fastboot
    includePlatformTools = true;
  };

  # Define the Flutter SDK
  flutter-sdk = pkgs.flutter.master; # You can specify a different channel or version if needed
in

pkgs.mkShell {
  packages = [
    android-sdk
    android-sdk.emulator
    android-sdk.platform-tools # Include platform tools in the shell
    flutter-sdk
    # Add any other packages you need for your development environment
  ];

  # Set environment variables for Flutter and Android SDK
  shellHook = ''
    export ANDROID_SDK_ROOT=${android-sdk}
    export PATH=$PATH:${flutter-sdk}/bin
    export PATH=$PATH:${android-sdk}/platform-tools
  '';
}
