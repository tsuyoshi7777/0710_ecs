import requests

def stock_availability(item):
    url = "https://notify-api.line.me/api/notify"
    access_token = 'n0CYWYzGFoDVOjK4dnyNkRqId5DlBObT7pnbdccDRf0'
    headers = {'Authorization': 'Bearer ' + access_token}

    message = 'id:'+str(item[0])+'、商品名:「'+item[1]+'」が「在庫あり」になりました'
    payload = {'message': message}
    r = requests.post(url, headers=headers, params=payload,)

def stock_not_availability(item):
    url = "https://notify-api.line.me/api/notify"
    access_token = 'n0CYWYzGFoDVOjK4dnyNkRqId5DlBObT7pnbdccDRf0'
    headers = {'Authorization': 'Bearer ' + access_token}

    message = 'id:'+str(item[0])+'、商品名:「'+item[1]+'」が「在庫なし」になりました。\
                [出荷状況]'+item[4]
    payload = {'message': message}
    r = requests.post(url, headers=headers, params=payload,)
