#!/usr/bin/env bash


PROJECT_MANAGER="uv" # "uv" or "poetry"
PY_VER="3.14,3.13,3.12,3.11,3.10" # comma separated python versions
# shellcheck disable=SC2034
PY_MAIN=${PY_VER%%,*}
OS="ubuntu-latest" # comma separated os versions, like "ubuntu-latest, macos-latest, windows-latest"
# shellcheck disable=SC2034
OS_MAIN=${OS%%,*}
CLI="no" # "yes" or "no"
PRE_COMMIT='prek' # 'pre-commit', 'prek' or '' to disable pre-commit setup
CHECKERS="ruff,ty,numpydoc" # comma separated checkers, any of ruff,black,autoflake,autopep8,isort,flake8,bandit,mypy,ty,numpydoc
PRE_COMMIT_PYPROJECT_OTHERS=1
PRE_COMMIT_HOOKS=1
PRE_COMMIT_ACTIONLINT=1
LICENSE="Apache-2.0" # License type, currently only Apache-2.0 is supported. Set empty to skip license setup.
USER=""
EMAIL=""

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
  repo_url=$(git remote get-url origin 2>/dev/null)
  if [ "$(basename "$repo_url")" = "python-template" ];then
    repo_url=""
  fi
fi
if [ -n "$repo_url" ];then
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
  echo "Please input your name (user name for GitHub): "
  read -r user
fi
if [ -z "$email" ];then
  echo "Please input your email address: "
  read -r email
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

function check {
  checker="$1"
  echo ",${CHECKERS}," | grep -q ",${checker},"
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

______________________________________________________________________

This repository is based on [rcmdnk/python-template](https://github.com/rcmdnk/python-template), $template_version
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

  if [ "$PRE_COMMIT" = "pre-commit" ];then
    pre_commit_url="[pre-commit](https://pre-commit.com/)"
    pre_commit_in_help="It checks codes with \`$PRE_COMMIT\` and runs tests with \`pytest\`.
"
  elif [ "$PRE_COMMIT" = "prek" ];then
    pre_commit_url="[prek](https://github.com/j178/prek)"
    pre_commit_in_help="It checks codes with \`$PRE_COMMIT\` and runs tests with \`pytest\`.
"
  elif [ -n "$PRE_COMMIT" ];then
    echo "Unknown PRE_COMMIT: $PRE_COMMIT" 1>&2
    exit 1
  fi

  if [ -n "$PRE_COMMIT" ];then
    cat << EOF

## Pre-commit checks

To check codes at the commit, use $pre_commit_url.

\`$PRE_COMMIT\` command will be installed in the $PROJECT_MANAGER environment.

First, run:

\`\`\`
$ $PRE_COMMIT install
\`\`\`

Then \`$PRE_COMMIT\` will be run at the commit.

Sometimes, you may want to skip the check. In that case, run:

\`\`\`
$ git commit --no-verify
\`\`\`

You can run \`$PRE_COMMIT\` on entire repository manually:

\`\`\`
$ $PRE_COMMIT run -a
\`\`\`
EOF
  fi

  cat << EOF

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

${pre_commit_in_help}It also makes a test coverage report and uploads it to [the coverage branch]($repo_url/tree/coverage).

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
EOF
  if [ -n "$LICENSE" ];then
    cat << EOF
license = "${LICENSE}"
EOF
  fi
  cat << EOF
keywords = []
classifiers = []
EOF
  if [ "$PROJECT_MANAGER" = "uv" ];then
    if [ -n "$PRE_COMMIT" ];then
      extras=""
      if check ruff;then
        extras="${extras:+${extras},}ruff"
      fi
      if check ty;then
        extras="${extras:+${extras},}ty"
      fi
      if [ "$PRE_COMMIT" = "prek" ];then
        extras="${extras:+${extras},}prek"
      fi
      if [ -n "$extras" ];then
        extras="[${extras}]"
      fi
      pyproject_pre_commit="
    \"pyproject-pre-commit${extras} >= 0.6.1\",
"
    fi
    cat << EOF
requires-python = ">=3.$py_min,<3.$((py_max+1))"
dependencies = []

EOF
    if [ -n "$repo_url" ];then
      cat << EOF
[project.urls]
Repository = "$repo_url"
Documentation = "$repo_url"
Homepage = "$repo_url"
Issue = "$repo_url/issues"
EOF
    fi

    if [ "$CLI" = "yes" ];then
      cat << EOF

[project.scripts]
$repo_name = "$repo_name_underscore:main"
EOF
    fi

    cat << EOF

[dependency-groups]
dev = [
    "tomli >= 2.4.0; python_version < '3.11'",
    "pytest >= 9.0.2",
    "pytest-cov >= 7.0.0",
    "pytest-xdist >= 3.8.0",
    "pytest-benchmark >= 5.2.3",
    "gitpython >= 3.1.46","$pyproject_pre_commit"
]

[build-system]
requires = ["uv_build>=0.8.0,<0.9.0"]
build-backend = "uv_build"
EOF
  else
    if [ -n "$repo_url" ];then
      cat << EOF
repository = "$repo_url"
homepage = "$repo_url"
EOF
    fi
    if [ -n "$PRE_COMMIT" ];then
      extras=""
      if check ruff;then
        extras="${extras:+${extras}, }\"ruff\""
      fi
      if check ty;then
        extras="${extras:+${extras}, }\"ty\""
      fi
      if [ "$PRE_COMMIT" = "prek" ];then
        extras="${extras:+${extras}, }\"prek\""
      fi
      if [ -n "$extras" ];then
        extras=", extras = [${extras}] "
      fi
      pyproject_pre_commit="
pyproject-pre-commit = { version = \">=0.6.1\"${extras}}
"
    fi
    cat << EOF

[tool.poetry.dependencies]
python = ">=3.$py_min,<3.$((py_max+1))"

[tool.poetry.group.dev.dependencies]
tomli = { version = ">=2.0.1", python = "<3.11"}
pytest = ">=9.0.2"
pytest-cov = ">= 7.0.0"
pytest-xdist = ">=3.8.0"
pytest-benchmark = ">=5.2.3"
gitpython = ">= 3.1.46"$pyproject_pre_commit
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

  if check ruff;then
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
    "PLR0913", # Too many arguments in function definition
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

  if check black;then
    cat << EOF

[tool.black]
line-length = 79
EOF
  fi

  if check autoflake;then
    cat << EOF

[tool.autoflake]
remove-all-unused-imports = true
expand-star-imports = true
remove-duplicate-keys = true
remove-unused-variables = true
EOF
  fi

  if check autopep8;then
    cat << EOF

[tool.autopep8]
ignore = "E203,E501,W503"
recursive = true
aggressive = 3
EOF
  fi

  if check isort;then
    cat << EOF

[tool.isort]
profile = "black"
line_length = 79
EOF

  fi

  if check flake8;then
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

  if check bandit;then
    cat << EOF

[tool.bandit]
exclude_dirs = ["tests"]
EOF

  fi

  if check mypy;then
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

  if check ty;then
    cat << EOF

[tool.ty.rules]
EOF
  fi

  if check numpydoc;then
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
if [ "$LICENSE" = "Apache-2.0" ];then
  sedi "s/2023/$year/" LICENSE
  sedi "s/@rcmdnk/@${user}/" LICENSE
else
  rm -f LICENSE
fi
# }}}

# src {{{
if [ "$repo_name_underscore" != "python_template" ];then
  mv "src/python_template" "src/$repo_name_underscore"
fi
if [ "$CLI" = "yes" ];then
  cat << EOF > "src/$repo_name_underscore/${repo_name_underscore}.py"
import logging
import sys

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)


def main() -> None:
    match len(sys.argv):
        case 1:
            logger.info('Hello World!')
        case 2:
            logger.info('Hello %s!', sys.argv[1])
        case _:
            logger.info('Hello %s!', ', '.join(sys.argv[1:]))


if __name__ == '__main__':
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
import logging
import sys

import pytest

from $repo_name_underscore import main


@pytest.mark.parametrize(
    ('argv', 'out'),
    [
        (['$repo_name_underscore'], 'Hello World!'),
        (['$repo_name_underscore', 'Alice'], 'Hello Alice!'),
        (
            ['$repo_name_underscore', 'Alice', 'Bob', 'Carol'],
            'Hello Alice, Bob, Carol!',
        ),
    ],
)
def test_main(
    argv: list[str], out: str, caplog: pytest.LogCaptureFixture
) -> None:
    caplog.set_level(logging.INFO)
    sys.argv = argv
    main()
    assert len(caplog.records) == 1
    assert caplog.records[0].getMessage() == out
EOF
fi
# }}}

# pre-commit {{{
if [ -n "$PRE_COMMIT" ];then
  {
    cat << EOF
repos:
- repo: https://github.com/rcmdnk/pyproject-pre-commit
  rev: v0.6.1
  hooks:
EOF
    if check ruff;then
      cat << EOF
    - id: ruff-lint-diff
    - id: ruff-lint
    - id: ruff-format-diff
    - id: ruff-format
EOF
    fi
    if check black;then
      cat << EOF
    - id: black-diff
    - id: black
    - id: blacken-docs
EOF
    fi
    if check autoflake;then
      cat << EOF
    - id: autoflake-diff
    - id: autoflake
EOF
    fi
    if check autopep8;then
      cat << EOF
    - id: autopep8-diff
    - id: autopep8
EOF
    fi
    if check isort;then
      cat << EOF
    - id: isort-diff
    - id: isort
EOF
    fi
    if check flake8;then
      cat << EOF
    - id: flake8
EOF
    fi
    if check bandit;then
      cat << EOF
    - id: bandit
EOF
    fi
    if check mypy;then
      cat << EOF
    - id: mypy
    #- id: dmypy
EOF
    fi
    if check ty;then
      cat << EOF
    - id: ty
EOF
    fi
    if check numpydoc;then
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
      args:
        - "-ignore=SC2129"  # allow individual redirects ({} >> file is not allowed in GitHub Actions' run)
EOF
    fi
  }  > .pre-commit-config.yaml
fi
# }}}

# .mise.toml {{{
if [ -n "$PRE_COMMIT" ];then
  enter_cmd="  \"[ -x \\\"$(git rev-parse --git-path hooks/pre-commit)\\\" ] ||$PROJECT_MANAGER run $PRE_COMMIT install >/dev/null\""
fi
{
  cat << EOF
[env]
_.python.venv = ".venv"

[settings]
experimental = true

[hooks]
enter = [
$enter_cmd
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
if [ -n "$PRE_COMMIT" ];then
  sedi "s/prek/$PRE_COMMIT/" .github/workflows/test.yml
else
  sedi "/^ *prek.*/d" .github/workflows/test.yml
fi
# }}}

rm -f setup.sh uv.lock .github/workflows/template_test.yml .github/FUNDING.yml
