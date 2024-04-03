import secrets
import string
import sys


def generate_password(length=12):
    # https://stackoverflow.com/a/39596292
    alphabet = string.ascii_letters + string.digits
    password = "".join(secrets.choice(alphabet) for i in range(length))
    return password


if len(sys.argv) < 2:
    PWD_LEN = 30
else:
    PWD_LEN = int(sys.argv[1])

NEW_PWD = generate_password(PWD_LEN)
print(NEW_PWD)
