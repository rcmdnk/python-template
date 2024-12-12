# python-template

Template for python project using poetry. abc.

This **README.md** will be overwritten by **setup.sh**.

[![test](https://github.com/rcmdnk/python-template/actions/workflows/test.yml/badge.svg)](https://github.com/rcmdnk/python-template/actions/workflows/test.yml)
[![test coverage](https://img.shields.io/badge/coverage-check%20here-blue.svg)](https://github.com/rcmdnk/python-template/tree/coverage)

## Repository initialization

Modify the repository info in **setup.sh** if necessary:

| Value             | Explanation                                                                                                                           | Default                       |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------ | :---------------------------- |
| `PROJECT_MANAGER` | Python project manager. [uv](https://docs.astral.sh/uv/) or [Poetry](https://python-poetry.org/).                                     | "uv"                          |
| `PY_VER`          | Python version. Multiple versions can be set as comma separated value like "3.10,3.9,3.8".                                            | "3.13,3.12,3.11,3.10"         |
| `PY_MAIN`         | Main python version used by GitHub Actions.                                                                                           | The first version in `PY_VER` |
| `OS`              | OS on which GitHub Actions job runs. Multiple OS can be set as comma separated value like "ubuntu-latest,macos-latest,windows-latest" | "ubuntu-latest"               |
| `OS_MAIN`         | Main OS used by GitHub Actions.                                                                                                       | The first OS in `OS`          |
| `CHECKERS`        | Comma separated linter and formatter list. Any of ruff, black, autoflake, autopep8, isort, flake8, bandit, mypy.                      | "ruff,mypy,numpydoc"          |
| `CLI`             | Set `yes` to create a template for command line interface.                                                                            | "no"                          |
| `USER`            | User name in **pyproject.toml** and **LICCENSE**.                                                                                     | `git config --get user.name`  |
| `EMAIL`           | Email address in **pyproject.toml**.                                                                                                  | `git config --get user.email` |

Run `setup.sh`.

## The repository features

The repository has following features:

- Environment management with [uv](https://docs.astral.sh/uv/) or [Poetry](https://python-poetry.org/).
- Code check/lint with [pre-commit](https://pre-commit.com/).
  - For Python
    - [ruff](https://docs.astral.sh/ruff/)
    - [Black](https://black.readthedocs.io/en/stable/)
    - [Flake8](https://flake8.pycqa.org/en/latest/) (actually, [pyproject-flake8](https://pypi.org/project/pyproject-flake8/) is used to read options from pyproject.toml)
    - [isort](https://pycqa.github.io/isort/)
    - [mypy](https://www.mypy-lang.org/)
    - [numpydoc](https://numpydoc.readthedocs.io/en/latest/)
  - For shell script
    - [ShellCheck](https://www.shellcheck.net/)
  - For Markdown
    - [mdformat](https://mdformat.readthedocs.io/en/stable/)
  - And other small checks including YAML/JSON/TOML checks.
  - All packages instead of **pre-commit-hooks** are managed by Poetry (**pyproject.toml**).
  - Most of options are managed by **pyproject.toml**.
- Tests using [pytest](https://docs.pytest.org/).
  - [pytest-xdist](https://pytest-xdist.readthedocs.io/en/latest/) is used for the parallel test.
- Automatic tests with [GitHub Actions](https://github.co.jp/features/actions).
  - Generate coverage results in coverage branch (made for `py_main` and `os_main`).
- Package version check/update with [Renovate](https://docs.renovatebot.com/).
  - To enable renovate, you need to [install Renovate into your repository](https://docs.renovatebot.com/getting-started/installing-onboarding/).
  - The example of the renovate.json is given in this template.
- .gitignore for Python
