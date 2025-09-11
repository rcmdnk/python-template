#!/usr/bin/env bash


PROJECT_MANAGER="uv" # "uv" or "poetry"
PY_VER="3.13,3.12,3.11,3.10" # comma separated python versions
# shellcheck disable=SC2034
PY_MAIN=${PY_VER%%,*}
OS="ubuntu-latest" # comma separated os versions, like "ubuntu-latest, macos-latest, windows-latest"
# shellcheck disable=SC2034
OS_MAIN=${OS%%,*}
CLI="no" # "yes" or "no"
CHECKERS="ruff,mypy,numpydoc" # comma separated checkers, any of ruff,black,autoflake,autopep8,isort,flake8,bandit,mypy,numpydoc
USER=""
EMAIL=""
PRE_COMMIT_PYPROJECT_OTHERS=1
PRE_COMMIT_HOOKS=1
PRE_COMMIT_ACTIONLINT=1

if [ "$PROJECT_MANAGER" != "uv" ] && [ "$PROJECT_MANAGER" != "poetry" ];then
  echo "Wrong PROJECT_MANAGER: $PROJECT_MANAGER, should be 'uv' or 'poetry'" 1>&2
  exit 1
fi

if [ "$PROJECT_MANAGER" = "uv" ];then
  manager_url="[uv](https://docs.astral.sh/uv/)"
else
  manager_url="[Poetry](https://python-poetry.org/)"
fi

template_version=v$(grep "^version" pyproject.toml|cut -d '=' -f2|tr -d '"'|tr -d ' ')

year=$(date +%Y)

user="$USER"
email="$EMAIL"

if type git >/dev/null 2>&1;then
  repo_url=$(git remote get-url origin)
  repo_url=${repo_url//git@github.com:/https:\/\/github.com\/}
  repo_url=${repo_url//ssh:\/\/git@github.com/https:\/\/github.com}

  repo_name=$(basename -s .git "$repo_url")
  repo_user=$(basename "$(dirname "$repo_url)")")
  if [ -z "$user" ];then
    user=$(git config --get user.name)
  fi
  if [ -z "$email" ];then
    email=$(git config --get user.email)
  fi
else
  repo_url=""
  repo_name=$(pwd | xargs basename)
  repo_user=$user
fi

if [ -z "$user" ];then
  user=user
fi
if [ -z "$email" ];then
  email="email@example.com"
fi

repo_name_underscore=${repo_name//-/_}

py_list=""
py_max=0
py_min=100
py_vers=""
for p in ${PY_VER//,/ };do
  py_list="${py_list}          - \"$p\"\n"
  if [ -n "$py_vers" ];then
    py_vers="${py_vers}, "
  fi
  py_vers="${py_vers}\"$p\""
  ver=${p#*.}
  if (( ver > py_max ));then
    py_max=$ver
  fi
  if (( ver < py_min ));then
    py_min=$ver
  fi
done

os_list=""
for o in ${OS//,/ };do
  os_list="${os_list}          - \"$o\"\n"
done

function sedi {
  local tmpfile
  tmpfile=$(mktemp)
  local cmd="$1"
  local file="$2"
  sed "$cmd" "$file" > "$tmpfile"
  mv "$tmpfile" "$file"
}

# README.md {{{
{
  cat << EOF
# $repo_name

[![test](https://github.com/$repo_user/$repo_name/actions/workflows/test.yml/badge.svg)](https://github.com/$repo_user/$repo_name/actions/workflows/test.yml)
[![test coverage](https://img.shields.io/badge/coverage-check%20here-blue.svg)](https://github.com/$repo_user/$repo_name/tree/coverage)

...

## Requirement

- Python ${py_vers//\"/}

## Installation

...

## Usage

...

Based on [rcmdnk/python-template](https://github.com/rcmdnk/python-template), $template_version
EOF
} > README.md
# }}}

# DEVELOPMENT.md {{{
{

  cat << EOF
# Development

## $PROJECT_MANAGER

Use $manager_url to setup environment.

To install $PROJECT_MANAGER, run:

\`\`\`
$ pip install $PROJECT_MANAGER
\`\`\`

Setup $PROJECT_MANAGER environment:
EOF

  if [ "$PROJECT_MANAGER" = "uv" ];then
    cat << EOF

\`\`\`
$ uv sync
\`\`\`

To enter the environment:

\`\`\`
$ source .venv/bin/activate
\`\`\`
EOF
  else
    cat << EOF

\`\`\`
$ poetry install
\`\`\`

Then enter the environment:

\`\`\`
$ poetry shell
\`\`\`
EOF
  fi

  cat << EOF

## pre-commit

To check codes at the commit, use [pre-commit](https://pre-commit.com/).

\`pre-commit\` command will be installed in the $PROJECT_MANAGER environment.

First, run:

\`\`\`
$ pre-commit install
\`\`\`

Then \`pre-commit\` will be run at the commit.

Sometimes, you may want to skip the check. In that case, run:

\`\`\`
$ git commit --no-verify
\`\`\`

You can run \`pre-commit\` on entire repository manually:

\`\`\`
$ pre-commit run -a
\`\`\`

## pytest

Tests are written with [pytest](https://docs.pytest.org/).

Write tests in **/tests** directory.

To run tests, run:

\`\`\`
$ pytest
\`\`\`

The default setting runs tests in parallel with \`-n auto\`.
If you run tests in serial, run:

\`\`\`
$ pytest -n 0
\`\`\`

## GitHub Actions

If you push a repository to GitHub, GitHub Actions will run a test job
by [GitHub Actions](https://github.co.jp/features/actions).

The job runs at the Pull Request, too.

It checks codes with \`pre-commit\` and runs tests with \`pytest\`.
It also makes a test coverage report and uploads it to [the coverage branch]($repo_url/tree/coverage).

You can see the test status as a badge in the README.

## Renovate

If you want to update dependencies automatically, [install Renovate into your repository](https://docs.renovatebot.com/getting-started/installing-onboarding/).
EOF
} > DEVELOPMENT.md
# }}}

# pyproject.toml {{{
{
  if [ "$PROJECT_MANAGER" = "uv" ];then
    authors="authors = [ { name = \"$user\", email = \"$email\" } ]"
  else
    authors="authors = [\"$user <$email>\"]"
  fi

  if [ "$PROJECT_MANAGER" = "uv" ];then
    echo "[project]"
  else
    echo "[tool.poetry]"
  fi
    cat << EOF
name = "$repo_name"
version = "0.1.0"
description = ""
${authors}
readme = "README.md"
license = "Apache-2.0"
keywords = []
classifiers = []
EOF
  if [ "$PROJECT_MANAGER" = "uv" ];then
    if echo "$CHECKERS" | grep -q ruff;then
      pyproject_pre_commit="pyproject-pre-commit[ruff] >= 0.4.2"
    else
      pyproject_pre_commit="pyproject-pre-commit >= 0.4.2"
    fi
    cat << EOF
requires-python = ">=3.$py_min,<3.$((py_max+1))"
dependencies = []

[project.urls]
Repository = "$repo_url"
Documentation = "$repo_url"
Homepage = "$repo_url"
Issue = "$repo_url/issues"
EOF

    if [ "$CLI" = "yes" ];then
      cat << EOF

[project.scripts]
$repo_name = "$repo_name_underscore:main"
EOF
    fi

    cat << EOF

[dependency-groups]
dev = [
    "tomli >= 2.0.1; python_version < '3.11'",
    "pytest >= 8.0.0",
    "pytest-cov >= 6.0.0",
    "pytest-xdist >= 3.3.1",
    "pytest-benchmark >= 5.0.0",
    "$pyproject_pre_commit",
    "gitpython >= 3.1.41",
    "types-pymysql>=1.1.0.20241103",
    "types-pyyaml>=6.0.12.20240917",
    "types-decorator>=5.1.8.20240310",
    "types-redis>=4.6.0.20241004",
    "types-six>=1.16.21.20241105",
]

[build-system]
requires = ["uv_build>=0.8.0,<0.9.0"]
build-backend = "uv_build"
EOF
  else
    if echo "$CHECKERS" | grep -q ruff;then
      pyproject_pre_commit='pyproject-pre-commit = { version = ">=0.4.2", extras = ["ruff"]}'
    else
      pyproject_pre_commit='pyproject-pre-commit = ">=0.4.2"'
    fi
    cat << EOF
repository = "$repo_url"
homepage = "$repo_url"

[tool.poetry.dependencies]
python = ">=3.$py_min,<3.$((py_max+1))"

[tool.poetry.group.dev.dependencies]
tomli = { version = ">=2.0.1", python = "<3.11"}
pytest = ">=8.0.0"
pytest-cov = ">= 6.0.0"
pytest-xdist = ">=3.3.1"
pytest-benchmark = ">=5.0.0"
$pyproject_pre_commit
gitpython = ">=3.1.41"
EOF
    if [ "$CLI" = "yes" ];then
      cat << EOF

[tool.poetry.scripts]
$repo_name = "$repo_name_underscore:main"
EOF
    fi
    cat << EOF
[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
EOF
  fi

  if echo "$CHECKERS" | grep -q ruff;then
    cat << EOF

[tool.pytest.ini_options]
addopts = "-n auto"
testpaths = ["tests",]

[tool.ruff]
line-length = 79

[tool.ruff.lint]
select = ["ALL"]

ignore = [
    "E203", # Not PEP8 compliant and black insert space around slice: [Frequently Asked Questions - Black 22.12.0 documentation](https://black.readthedocs.io/en/stable/faq.html#why-are-flake8-s-e203-and-w503-violated)
    "E501", # Line too long. Disable it to allow long lines of comments and print lines which black allows.
    "D100", "D102", "D103", "D104", "D105", "D106", "D107", # Missing docstrings other than class (D101)
    "D401", # First line should be in imperative mood
    "D211", # \`one-blank-line-before-class\` (D203) and \`no-blank-line-before-class\` (D211) are incompatible. Ignoring \`one-blank-line-before-class\`.
    "D213", # \`multi-line-summary-first-line\` (D212) and \`multi-line-summary-second-line\` (D213) are incompatible. Ignoring \`multi-line-summary-second-line\`.
    "COM812", "D203", "ISC001", # The following rules may cause conflicts when used with the formatter: \`COM812\`, \`D203\`, \`ISC001\`. To avoid unexpected behavior, we recommend disabling these rules, either by removing them from the \`select\` or \`extend-select\` configuration, or adding them to the \`ignore\` configuration.
    "FBT001", # Boolean-typed positional argument in function definition
    "FBT002", # Boolean default positional argument in function definition
    "FBT003", # Boolean positional value in function call
    "TID252", # Prefer absolute imports over relative imports from parent modules
    "PLC0415", # \`import\` should be at the top-level of a file
]

[tool.ruff.lint.per-file-ignores]
"tests/**" = [
    "S101", # Use of \`assert\` detected
    "DTZ001", # \`datetime.datetime()\` called without a \`tzinfo\` argument
    "PLR2004", # Magic value used in comparison
]

[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.flake8-quotes]
inline-quotes = "single"

[tool.ruff.format]
quote-style = "single"
docstring-code-format = true
EOF
  fi

  if echo "$CHECKERS" | grep -q black;then
    cat << EOF

[tool.black]
line-length = 79
EOF
  fi

  if echo "$CHECKERS" | grep -q autoflake;then
    cat << EOF

[tool.autoflake]
remove-all-unused-imports = true
expand-star-imports = true
remove-duplicate-keys = true
remove-unused-variables = true
EOF
  fi

  if echo "$CHECKERS" | grep -q autopep8;then
    cat << EOF

[tool.autopep8]
ignore = "E203,E501,W503"
recursive = true
aggressive = 3
EOF
  fi

  if echo "$CHECKERS" | grep -q isort;then
    cat << EOF

[tool.isort]
profile = "black"
line_length = 79
EOF

  fi

  if echo "$CHECKERS" | grep -q flake8;then
    cat << EOF

[tool.flake8]
# E203 is not PEP8 compliant and black insert space around slice: [Frequently Asked Questions - Black 22.12.0 documentation](https://black.readthedocs.io/en/stable/faq.html#why-are-flake8-s-e203-and-w503-violated)
# E501: Line too long. Disable it to allow long lines of comments and print lines which black allows.
# W503 is the counter part of W504, which follows current PEP8: [Line break occurred before a binary operator (W503)](https://www.flake8rules.com/rules/W503.html)
# D100~D106: Missing docstrings other than class (D101)
# D401: First line should be in imperative mood
ignore = "E203,E501,W503,D100,D102,D103,D104,D105,D106,D401"
max-complexity = 10
docstring-convention = "numpy"
EOF

  fi

  if echo "$CHECKERS" | grep -q bandit;then
    cat << EOF

[tool.bandit]
exclude_dirs = ["tests"]
EOF

  fi

  if echo "$CHECKERS" | grep -q mypy;then
    cat << EOF

[tool.mypy]
files = ["src/**/*.py"]
strict = true
warn_return_any = false
ignore_missing_imports = true
scripts_are_modules = true
install_types = true
non_interactive = true
EOF
  fi

  if echo "$CHECKERS" | grep -q numpydoc;then
    cat << EOF

[tool.numpydoc_validation]
checks = [
    "all",   # report on all checks, except the below
    "EX01",  # "No examples section found"
    "ES01",  # "No extended summary found"
    "SA01",  # "See Also section not found"
    "GL08",  # "The object does not have a docstring"
    "PR01",  # "Parameters {missing_params} not documented"
    "PR02",  # "Unknown parameters {unknown_params}"
    "RT01",  # "No Returns section found"
]
EOF
  fi
} > pyproject.toml
# }}}

# LICENSE {{{
sedi "s/2023/$year/" LICENSE
sedi "s/@rcmdnk/@${user}/" LICENSE
# }}}

# src {{{
if [ "$repo_name_underscore" != "python_template" ];then
  mv "src/python_template" "src/$repo_name_underscore"
fi
if [ "$CLI" = "yes" ];then
  cat << EOF > "src/$repo_name_underscore/${repo_name_underscore}.py"
import sys


def main() -> None:
    match len(sys.argv):
        case 1:
            print("Hello World!")
        case 2:
            print(f"Hello {sys.argv[1]}!")
        case _:
            print(f"Hello {', '.join(sys.argv[1:])}!")


if __name__ == "__main__":
    main()
EOF
  cat << EOF > "src/$repo_name_underscore/__init__.py"
from .${repo_name_underscore} import main

__all__ = ['__version__', 'main']


def __getattr__(name: str) -> str:
    if name == '__version__':
        from .version import __version__

        return __version__
    msg = f'module {__name__} has no attribute {name}'
    raise AttributeError(msg)
EOF
fi
# }}}

# tests {{{
sedi "s/python_template/$repo_name_underscore/" tests/test_version.py
if [ "$PROJECT_MANAGER" = "poetry" ];then
  sedi "s/\['project'\]/\['tool'\]\['poetry'\]/" tests/test_version.py
fi
if [ "$CLI" = "yes" ];then
  cat << EOF > "tests/test_${repo_name_underscore}.py"
import sys

import pytest

from $repo_name_underscore import main


@pytest.mark.parametrize(
    "argv, out",
    [
        (["$repo_name_underscore"], "Hello World!\n"),
        (["$repo_name_underscore", "Alice"], "Hello Alice!\n"),
        (
            ["$repo_name_underscore", "Alice", "Bob", "Carol"],
            "Hello Alice, Bob, Carol!\n",
        ),
    ],
)
def test_main(argv, out, capsys):
    sys.argv = argv
    main()
    captured = capsys.readouterr()
    assert captured.out == out
EOF
fi
# }}}

# pre-commit {{{
{
  cat << EOF
repos:
- repo: https://github.com/rcmdnk/pyproject-pre-commit
  rev: v0.4.2
  hooks:
EOF
  if echo "$CHECKERS" | grep -q ruff;then
    cat << EOF
    - id: ruff-lint-diff
    - id: ruff-lint
    - id: ruff-format-diff
    - id: ruff-format
EOF
  fi
  if echo "$CHECKERS" | grep -q black;then
    cat << EOF
    - id: black-diff
    - id: black
    - id: blacken-docs
EOF
  fi
  if echo "$CHECKERS" | grep -q autoflake;then
    cat << EOF
    - id: autoflake-diff
    - id: autoflake
EOF
  fi
  if echo "$CHECKERS" | grep -q autopep8;then
    cat << EOF
    - id: autopep8-diff
    - id: autopep8
EOF
  fi
  if echo "$CHECKERS" | grep -q isort;then
    cat << EOF
    - id: isort-diff
    - id: isort
EOF
  fi
  if echo "$CHECKERS" | grep -q flake8;then
    cat << EOF
    - id: flake8
EOF
  fi
  if echo "$CHECKERS" | grep -q bandit;then
    cat << EOF
    - id: bandit
EOF
  fi
  if echo "$CHECKERS" | grep -q mypy;then
    cat << EOF
    - id: mypy
    #- id: dmypy
EOF
  fi
  if echo "$CHECKERS" | grep -q numpydoc;then
    cat << EOF
    - id: numpydoc-validation
EOF
  fi
  if [ "$PRE_COMMIT_PYPROJECT_OTHERS" -eq 1 ];then
    cat << EOF
    - id: shellcheck
    - id: mdformat-check
    - id: mdformat
    - id: validate-pyproject
EOF
  fi
  if [ "$PRE_COMMIT_HOOKS" -eq 1 ];then
     cat <<EOF
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v6.0.0
  hooks:
    - id: check-yaml
    - id: check-json
    - id: check-toml
    - id: check-case-conflict
    - id: check-merge-conflict
      args:
        - "--assume-in-merge"
    - id: end-of-file-fixer
    - id: fix-byte-order-marker
    - id: mixed-line-ending
    - id: trailing-whitespace
    - id: debug-statements
    - id: detect-private-key
    - id: detect-aws-credentials
      args:
        - "--allow-missing-credentials"
EOF
  fi
   if [ "$PRE_COMMIT_ACTIONLINT" -eq 1 ];then
     cat <<EOF
- repo: https://github.com/rhysd/actionlint
  rev: v1.7.7
  hooks:
    - id: actionlint
EOF
  fi
}  > .pre-commit-config.yaml
# }}}

# .mise.toml {{{
{
  cat << EOF
[env]
_.python.venv = ".venv"

[settings]
experimental = true

[hooks]
enter = [
EOF
  if [ "$PROJECT_MANAGER" = "uv" ];then
    cat << EOF
  "[ -x \"$(git rev-parse --git-path hooks/pre-commit)\" ] || uv run pre-commit install >/dev/null"
EOF
  else
    cat << EOF
  "[ -x \"$(git rev-parse --git-path hooks/pre-commit)\" ] || poetry run pre-commit install >/dev/null"
EOF
  fi
  cat << EOF
]
EOF
} > .mise.toml
# }}}


# .github/workflows/test.yml {{{
sedi "s/default: \"3.*\"/default: \"$PY_MAIN\"/" .github/workflows/test.yml
sedi "s/          - \"3.*\"/$py_list/" .github/workflows/test.yml
sedi "s/inputs.main_py_ver || '3.*'/inputs.main_py_ver || '$PY_MAIN'/" .github/workflows/test.yml
sedi "s/python-version: \[\"3.*\"\]/python-version: \[$py_vers\]/" .github/workflows/test.yml
sedi "s/default: \"ubuntu-latest\"/default: \"$OS_MAIN\"/" .github/workflows/test.yml
sedi "s/          - \"ubuntu-latest\"/$os_list/" .github/workflows/test.yml
sedi "s/inputs.main_os || 'ubuntu-latest'/inputs.main_os || '$OS_MAIN'/" .github/workflows/test.yml
sedi "s/os: \[ubuntu-latest\]/os: \[$OS\]/" .github/workflows/test.yml
sedi "s/setup-type: 'uv'/setup-type: '$PROJECT_MANAGER'/" .github/workflows/test.yml
# }}}

rm -f setup.sh uv.lock .github/workflows/template_test.yml .github/FUNDING.yml
