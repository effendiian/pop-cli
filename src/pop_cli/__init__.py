"""Module for pop_cli package."""

import importlib.metadata

# This __all__ variable is used to specify which attributes of the module should be exported when using 'from pop_cli import *'.
__all__ = ["__version__"]

try:
    # Get the version from the installed package metadata
    __version__ = importlib.metadata.version("pop-cli")
except importlib.metadata.PackageNotFoundError:
    # Editable / not installed
    __version__ = "0.0.0"
