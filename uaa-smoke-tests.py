#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

import requests
from bs4 import BeautifulSoup


def test_login():
    resp = requests.get(os.getenv('BASE_URL'))

    # Assert OK
    assert resp.status_code is 200

    page = BeautifulSoup(resp.content)

    # Assert SAML link with GSA IDP
    links = page.find_all('a', class_='saml-login-link')
    next(
        each for each in links
        if 'idp=gsa' in each.attrs['href']
    )

    assert len(page.find_all('input', class_='island-button')) == 1
    assert len(page.find_all('div', class_='modal-body')) == 1


if __name__ == "__main__":
    test_login()
