def sha256file(filepath):
    import hashlib

    _hash = hashlib.sha256()

    # https://stackoverflow.com/a/22058673/12124525
    with open(filepath, "rb") as f:
        while True:
            data = f.read(65536)
            if not data:
                break

            _hash.update(data)

    return _hash.hexdigest()


def substring(value, start, end):
    return value[start:end]
