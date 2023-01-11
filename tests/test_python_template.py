import sys

import pytest

import python_template


@pytest.mark.parametrize(
    "argv, out",
    [
        (["python_template"], "Hello World!\n"),
        (["python_template", "Alice"], "Hello Alice!\n"),
        (
            ["python_template", "Alice", "Bob", "Carol"],
            "Hello Alice, Bob, Carol!\n",
        ),
    ],
)
def test_main(argv, out, capsys):
    sys.argv = argv
    python_template.main()
    captured = capsys.readouterr()
    assert captured.out == out
