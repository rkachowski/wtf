```
╱╱▏╱▏╱▏╱╱╱╱╱╱▏╱╱╱╱╱▏
▉╱▉╱▉╱▏▉▉▉▉▉╱┈▉▉▉▉╱
▉╱▉╱▉╱▏┈┈▉╱▏┈┈▉╱╱╱╱▏
▉╱▉╱▉╱▏┈┈▉╱▏┈┈▉▉▉▉╱
▉▉▉▉▉╱┈┈┈▉╱┈┈┈▉╱

wooget test framework
```

> Make testing of wooget packages easier

## Dependencies
### iOS device support
* iFuse http://www.libimobiledevice.org/
* osxfuse https://osxfuse.github.io/

`$ brew install Caskroom/cask/osxfuse homebrew/fuse/ifuse`

## Functionality

```
Commands:
  wtf ci                   # ci related commands
  wtf help [COMMAND]       # Describe available commands or one specific command
  wtf install FILE         # installs the app provided
  wtf launch FILE          # launches the app from the file
  wtf sdkbot ROOM MESSAGE  # make sdk bot say something to a room
  wtf stop FILE            # kills the app from the file
  wtf uninstall FILE       # uninstalls the app provided

Commands:
  wtf unity build --path=PATH --platform=PLATFORM               # Build artifacts for project (.apk / .app)
  wtf unity create_project --package-id=PACKAGE_ID --path=PATH  # Generate project with package_id as dependency + install dependencies
  wtf unity help [COMMAND]                                      # Describe subcommands or one specific subcommand
  wtf unity run_tests --path=PATH --platform=PLATFORM           # Deploy and run test artifacts on devices

```
