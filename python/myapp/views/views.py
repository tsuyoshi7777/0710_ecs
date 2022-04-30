from django.views.generic import TemplateView
from django.shortcuts import render


class SampleTemplateView(TemplateView):
    template_name = "myapp/index.html"


import MySQLdb

def db_list(request):

    # 接続する
    con = MySQLdb.connect(
            user='admin',
            passwd='t19871027',
            host='database-1.cqdaaoulhur2.ap-northeast-1.rds.amazonaws.com',
            db='first',
            charset="utf8")

    # カーソルを取得する
    cur= con.cursor()

    # クエリを実行する
    sql = "select * from test"
    cur.execute(sql)

    # 実行結果をすべて取得する
    datas = cur.fetchall()

    cur.close()
    con.close()

    return render(request, 'myapp/db_list.html',  {
            'datas': datas,
    })


if __name__ == "__main__":
    db_list()
