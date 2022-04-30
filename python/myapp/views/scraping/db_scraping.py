from django.shortcuts import render
from django.http import HttpResponse
from django.shortcuts import redirect
from requests_html import HTMLSession
import requests
import re

from .modules import scraping_ways
from .databases import db_datas
from ..notification import line


# 0 id
# 1 item
# 2 url
# 3 stock

def db_scraping(request):
    for data in db_datas.db_list():
        pattern_amazon = r"https?://www.amazon.co.jp[\w/:%#\$&\?\(\)~\.=\+\-]+"
        pattern_rakuten = r"https?://\w+.rakuten.co.jp[\w/:%#\$&\?\(\)~\.=\+\-]+"

        data = list(data)
        # AMAZONの場合（URLスクレイピング）
        if re.match(pattern_amazon, data[2]):
            stock_pattern_words, item_stock = scraping_ways.url_scraping(data[2])

            if re.search(stock_pattern_words, item_stock):

                if data[3] == 0:
                    line.stock_availability(data)

                data[3] = 1
                db_datas.db_save(data)

            else:

                if data[3] == 1:
                    data.append(item_stock)
                    line.stock_not_availability(data)

                data[3] = 0
                db_datas.db_save(data)



        # 楽天の場合（API）
        elif re.match(pattern_rakuten, data[2]):
                item_r, stock = scraping_ways.api_scraping(data[1])

                if stock == 1:
                    if stock != data[3]:
                        line.stock_availability(data)
                    data[2] = item_r['itemUrl']
                    data[3] = stock
                    db_datas.db_save(data)
                elif stock == 0:
                    if stock != data[3]:
                        line.stock_not_availability(data)


    datas = db_datas.db_list()
    return render(request, 'myapp/db_list.html', {
            'datas': datas,
    })
