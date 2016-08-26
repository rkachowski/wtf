# wdk test framework

> Test SDK libs on devices

## Dependencies
### iOS device support
* iFuse http://www.libimobiledevice.org/
* osxfuse https://osxfuse.github.io/

`$ brew install Caskroom/cask/osxfuse homebrew/fuse/ifuse`

## Functionality

```
Commands:
  wtf build --path=PATH                                      # Build artifacts for project (.apk / .app)
  wtf ci_setup --package-id=PACKAGE_ID --path=PATH           # make_test_project for ci
  wtf deploy_and_run --path=PATH --platform=PLATFORM         # Deploy and run test artifacts on devices
  wtf help [COMMAND]                                         # Describe available commands or one specific command
  wtf install FILE                                           # installs the app provided
  wtf jenkinsfile --package-id=PACKAGE_ID                    # generate a jenkinsfile for the ci
  wtf launch FILE                                            # launches the app from the file
  wtf make_test_project --package-id=PACKAGE_ID --path=PATH  # Generate project with package_id as dependency + install dependencies
  wtf sdkbot ROOM MESSAGE                                    # make sdk bot say something to a room
  wtf stop FILE                                              # kills the app from the file
  wtf uninstall FILE                                         # uninstalls the app provided

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist
```
