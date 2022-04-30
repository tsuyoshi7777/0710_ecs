import requests
import re
import csv
import sys
import codecs
import math
import random
from time import sleep
from requests_html import HTMLSession


def url_scraping(a):

    session = HTMLSession()
    r = session.get(a)

    stock_pattern_words = r'(在庫あり|\d+(~|-|～|ー)\d+(日|週間|か月)以内に発送|残り\d+点)'

    availability = r.html.find('#availability')
    item_stock = availability[0].text


    return stock_pattern_words, item_stock


def api_scraping(a):

    url = 'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706'
    print(a)
    payload = {
        'applicationId': 1019791696507795307,
        'hits': 5,#一度のリクエストで返してもらう最大個数（MAX30)
        # 'shopCode':'dvdoutlet',#ショップID
        'keyword': a.encode('utf-8'),
        'outOfStockFlag':0, #品切れや販売終了など購入不可の商品は結果に表示させない
        'page':1,#何ページ目か
        # 'postageFlag':1,#送料込みの商品に限定
        }
    r = requests.get(url, params=payload)
    resp = r.json()

    Items = resp['Items']
    for i in resp['Items']:
        item_r = i['Item']
        stock = item_r['availability']

        if stock == 1:
            return item_r, stock
