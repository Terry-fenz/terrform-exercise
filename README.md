# 練習

1. 建立 ec2
    * terraform 狀態存放至 s3
        * 利用 workspace 切換環境
    * 建立一組 vpc
    * 建立 ec2
        * 建立 ssh key
        * security group 開放 ssh 權限
2. ec2 環境配置
    * ec2 配置模組化
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
