import random
import string
import sys


def generate_password(length=12):
    characters = string.ascii_letters + string.digits
    password = "".join(random.choice(characters) for i in range(length))
    return password


if len(sys.argv) < 2:
    pwd_len = 12
else:
    pwd_len = int(sys.argv[1])

new_password = generate_password(pwd_len)
print(new_password)
