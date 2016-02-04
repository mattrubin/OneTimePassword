# Contributing

**Pull requests are welcome!**

If you encounter a problem with OneTimePassword, feel free to [open an issue][issues]. If you know how to fix the bug or implement the desired feature, a pull request is even better.

A great pull request:
- Follows the coding style and conventions of the project.
- Adds tests to cover the added functionality or fixed bug.
- Is accompanied by a clear explanation of its purpose.
- Remains as simple as possible while achieving its intended goal.

Please note that this project is released with a [Contributor Code of Conduct][conduct]. By participating in this project you agree to abide by its terms.

## Getting Started

1. Check out the latest version of the project:
```
git clone https://github.com/mattrubin/OneTimePassword.git
```

2. Check out the project's dependencies:
```
git submodule update --init --recursive
```

3. Open the `OneTimePassword.xcworkspace` file.
> If you open the `.xcodeproj` instead, the project will not be able to find its dependencies.

4. Build and run the "OneTimePassword" scheme.

## Managing Dependencies

OneTimePassword uses [Carthage][] to manage its dependencies, but it does not currently use Carthage to build those dependencies. The dependent projects are checked out as submodules, are included in `OneTimePassword.xcworkspace`, and are built by Xcode as target dependencies of the OneTimePassword framework.

To check out the dependencies, simply follow the "Getting Started" instructions above.

To update the dependencies, modify the [Cartfile][] and run:
```
$ carthage update --no-build --use-submodules
```


[issues]: https://github.com/mattrubin/OneTimePassword/issues
[conduct]: CONDUCT.md
[Carthage]: https://github.com/Carthage/Carthage
[Cartfile]: https://github.com/mattrubin/OneTimePassword/blob/master/Cartfile
