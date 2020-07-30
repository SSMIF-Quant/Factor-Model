from functools import wraps


def NonNullArgs(f):
    """
    :param f: function which cannot take in null arguments
    :return: the original function with arguments validated as non-null, raised a ValueError if a null arg is found
    """
    @wraps(f)
    def wrap(*args, **kwargs):
        for arg in args:
            if arg is None:
                raise ValueError("Null positional argument found. Error")
        for kwarg in kwargs:
            if kwarg is None:
                raise ValueError("Null keyword argument found. Error")
        return f(*args, **kwargs)
    return wrap
