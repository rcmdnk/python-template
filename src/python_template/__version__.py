def __getattr__(name: str) -> str:
    if name == '__version__':
        import importlib.metadata

        return importlib.metadata.version(__package__ or __name__)
    msg = f'module {__name__} has no attribute {name}'
    raise AttributeError(msg)
