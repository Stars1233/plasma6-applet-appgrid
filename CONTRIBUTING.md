# Contributing

Thanks for considering a contribution. This document covers building from
source, the patch workflow, and the bits of style we care about.

## Build

Build deps (Arch names; see `packaging/*` for other distros):

```
plasma-workspace plasma-activities plasma-activities-stats
kservice ki18n kiconthemes kcoreaddons kwindowsystem kio krunner
libplasma kpackage qt6-base qt6-declarative layer-shell-qt
appstream-qt extra-cmake-modules cmake gettext
```

Configure + build the plasmoid:

```sh
cmake --preset release      # see CMakePresets.json for other presets
cmake --build build
```

Install to `~/.local/share/plasma/plasmoids/` (for dev iteration without
touching system paths) via `makepkg -si` from the bundled `PKGBUILD`, or
`cmake --install build --prefix ~/.local`. Then in Plasma:
*Add Widgets → AppGrid*.

## Run the tests

```sh
cmake --preset tests
cmake --build build-tests
QT_QPA_PLATFORM=offscreen ctest --test-dir build-tests
```

Tests cover the C++ models (search ranking, filter, sort, runner filter,
unified search, plugin helpers, …) and a QtQuickTest harness for the QML
controllers under `tests/qml/`. New behaviour should land with coverage.

## Style

- C++: `clang-format -i` and `clang-tidy` are enforced by CI; the config
  files live at the repo root. Run `clang-format -i src/<file>` before
  pushing.
- QML: `qmllint -I /usr/lib/qt6/qml package/contents/ui/<file>.qml`. The
  config sits at `.qmllint.ini`.
- Comments: explain *why* — the hidden constraint, the bug fix, the
  invariant. Don't restate *what* the code does. No multi-paragraph
  docstrings on internal helpers.
- Identifiers: descriptive names; underscores reserved for private
  state-flag properties (`_snapHeight`, `_gridRevealed`).
- KDE-flavoured idioms: prefer Kirigami / PlasmaComponents over raw
  Qt Quick Controls where a themed equivalent exists; respect
  `Kirigami.Units` for sizing and spacing.

## Commit messages

Conventional-Commits style — the CI changelog generator (`git-cliff`) groups
by type:

```
<type>(<scope>): <subject>

<body — wrap at 72 cols, explain the why>
```

Common types: `feat`, `fix`, `refactor`, `perf`, `docs`, `chore`,
`build`, `ci`, `polish`, `test`. Scope is the affected module (e.g.
`search`, `config`, `ui`, `packaging`). Issue references in the
subject (`fix(search): … (#151)`) when applicable.

## Pull requests

- Fork → branch → push → PR against `main` (stable bugs against
  `maintenance/<series>`).
- Keep PRs focused. Unrelated cleanups belong in their own PR.
- CI gates the merge: clang-format, clang-tidy, codespell, qmllint,
  cppcheck, tests. Failures block — fix locally before pushing.
- New user-facing strings: wrap in `i18nd("dev.xarbit.appgrid", …)` or
  `i18ndc(...)` with a translator context.
- Don't commit pre-built packages, screenshots, or local-only notes.
  `.gitignore` already covers `*.pkg.tar.zst`, `notes/`, `result/`, etc.

## Reporting bugs / requesting features

Use the issue templates under
[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/). Include AppGrid
version (Settings → `i:` view), Plasma version, distro, and reproducer
steps. Triage labels follow `bug`, `enhancement`,
`upstream-limitation`, `regression`, `needs-info`.

## License

By contributing you agree your changes are licensed under GPL-2.0-or-later,
matching the project license.
