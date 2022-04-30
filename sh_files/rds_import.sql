-- データベース選択
use first;

-- ↓
-- テーブル作成
create table if not exists test( id int, name varchar(40), url varchar(300), stock int, primary key(id) );

-- ↓
-- sqlデータをimport
load data local infile "/Users/tsuyoshitakezawa/Desktop/0710/csv_files/test.csv" into table test fields terminated by ',' optionally enclosed by '"';

-- ↓
-- インポートしたテーブルを表示
select * from test;
