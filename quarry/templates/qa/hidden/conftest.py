"""conftest for hidden tests.
Adds the project root to sys.path so tests can import the package under test.
Adjust PACKAGE if your importable package name differs from the project dir.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(HERE))
PACKAGE = os.path.basename(PROJECT_ROOT)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)