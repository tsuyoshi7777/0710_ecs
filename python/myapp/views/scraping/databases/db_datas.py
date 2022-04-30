from django.shortcuts import render

import MySQLdb


def db_list():

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

    return datas


def db_save(x):

    con = MySQLdb.connect(
            user='admin',
            passwd='t19871027',
            host='database-1.cqdaaoulhur2.ap-northeast-1.rds.amazonaws.com',
            db='first',
            charset="utf8")

    # カーソルを取得する
    cur= con.cursor()
    sql = ('''
    UPDATE  test
    SET     stock = %s
    WHERE   id = %s
    ''')

    param = (x[3], x[0])
    
    cur.execute(sql, param)

    con.commit()

    print(cur.rowcount, "件の書き換え")
    print(x)
