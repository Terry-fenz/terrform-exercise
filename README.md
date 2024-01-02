# 練習

1. 建立 ec2
    * terraform 狀態存放至 s3
    * security group 開放 ssh 權限
    * 上傳 ssh key
2. ec2 環境配置
    * 初始化 docker
    * harbor 連線設定
3. 建立 redshift
    * security group 開放 ec2 連線
    * 帳密讀取自 aws secrets manager
4. dms 設定
5. 告警配置
    * sns 配置
    * lamda 配置
    * CloudWatch event 配置
