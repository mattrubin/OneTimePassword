## Getting Started

1. Check out the latest version of the project using Git.

2. Check out the project's dependencies with `git submodule init` and `git submodule update`.

3. Open the `OneTimePassword.xcworkspace` file.
> If you open the `.xcodeproj` instead, the app will not be able to find its dependencies.

4. Build and run the "OneTimePassword" scheme.

## Dependencies

OneTimePassword uses [Carthage](https://github.com/Carthage/Carthage) to manage its dependencies, but it does not currently use Carthage to build those dependencies. The dependent projects are checked out as submodules, are included in `OneTimePassword.xcworkspace`, and are built by Xcode as target dependencies of the OneTimePassword framework.

To check out the dependencies, simply follow the "Getting Started" instructions above.

To update the dependencies, modify the [Cartfile](https://github.com/mattrubin/OneTimePassword/blob/master/Cartfile) and run:
```
$ carthage update --no-build --use-submodules
```
