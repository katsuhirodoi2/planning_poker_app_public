## 本レポジトリ（プランニングポーカーアプリ）の利用方法

### 1. Flutterプロジェクトの作成とレポジトリ上のファイルのコピー

1. ローカル端末にて、Flutterプロジェクトを作成する

```
 flutter create planning_poker_app

 以下はWeb版のプロジェクトを有効にするための手順
  flutter channel stable
  flutter upgrade
  flutter config --enable-web
  cd planning_poker_app
  flutter create .
```

2. 本レポジトリをローカル端末の1で作成されたディレクトリ以外の場所にクローンする

3. 1で作成されたディレクトリ内に、2でクローンしたディレクトリ内のファイルを上書きコピーする



### 2. Firebaseプロジェクトを作成する

本アプリケーション用のFirebaseプロジェクトを作成する

※大まかには、Firebaseプロジェクトを作成後、Firebase Database、Storage、Hostingを構築（開始）する

※詳細な作成方法はFirebaseのドキュメント等を参照のこと

#### FirebaseにAndroidアプリを登録する

FirebaseのAndroidアプリ登録後、FirebaseのAndroidアプリの情報表示画面にある「SDKの手順を確認する」を開く

すると「Android アプリに Firebase を追加」の画面が開くので手順に従って対応する。

##### 手順詳細

1. FirebaseのAndroidアプリの構成ファイル「google-services.json」をダウンロードする

2. ダウンロードした「google-services.json」を

```
planning_poker_app/android/app/
```

配下に置く


3. Firebase SDKを追加する（「Android アプリに Firebase を追加」の画面に記載の手順を参考に対応する）


#### FirebaseにAppleアプリを登録する

FirebaseのAppleアプリ登録後、FirebaseのAppleアプリの情報表示画面にある「SDKの手順を確認する」を開く

すると「Apple アプリへの Firebase の追加」の画面が開くので手順に従って対応する。

##### 手順詳細

1. FirebaseのAppleアプリの設定ファイル「GoogleService-Info.plist」をダウンロードする

2. ダウンロードした「GoogleService-Info.plist」を

```
planning_poker_app/ios/Runner/
```

配下に置く

3. planning_poker_app/ios/Runner.xcworkspaceをXcodeで開き、File -> Add File to Runner...より「GoogleService-Info.plist」を選択し、Xcodeに「GoogleService-Info.plist」を追加する（認識させる）

「Apple アプリに Firebase を追加」の画面に記載されている「Firebase SDKの追加」および「初期化コードの追加」の手順は実施不要である認識

#### Firebaseにウェブアプリを登録する

Firebaseのウェブアプリ登録後、Firebaseのウェブアプリの情報表示画面にある「SDKの設定と構成」の欄に記載の手順を実行する



### 3. Firebaseとの接続設定（main.dart）

planning_poker_app/lib/main.dart

の以下コードのXXXXXXXの部分をFirebaseのウェブアプリの情報表示画面に表示されている同様の情報と同じ値に書き換える。

```
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        authDomain: "XXXXXXXXXXXXXXXXXXX.firebaseapp.com",
        projectId: "XXXXXXXXXXXXXXXXXXX",
        storageBucket: "XXXXXXXXXXXXXXXXXXX.appspot.com",
        messagingSenderId: "XXXXXXXXXXXX",
        appId: "1:XXXXXXXXXXXX:web:XXXXXXXXXXXXXXXXXXXX",
        measurementId: "G-XXXXXXXXXX"),
  );
```


### 4. Firebase StorageにCORSの設定をする

```
設定する
gsutil cors set cors.json gs://xxxx.appspot.com 

※xxxの部分は、実際のFirebase StorageのURLに置き換える

設定できたことを確認する
gsutil cors get gs://xxxx.appspot.com 
```



### 5. Web版アプリの環境構築とデプロイ

https://firebase.google.com/docs/hosting/frameworks/flutter?hl=ja

を参考に対応する。なお、デプロイ前にプロジェクトルート（planning_poker_app）直下にて、

```
flutter build web
```

コマンドの実行が必要と思われる。



### 6. Androidアプリの設定とデプロイ

Androidアプリ用の調整は未実施（後日公開予定）



### 7. Appleアプリの設定とデプロイ

1. プロジェクトルート直下にて、

```
flutter build ios --release
```

コマンドを実行する

2. Xcodeにてアーカイブ処理を行う
  
XcodeのメニューからProduct -> Archiveを選択する。これにより、アーカイブプロセスが開始され、成功すると、Organizerウィンドウが表示される。

3. Xcodeからストアにアップロードする

Organizerウィンドウで作成したアーカイブを選択し、Distribute Appボタンをクリックする。次に、App Store Connectを選択し、アップロードプロセスを続行する。

4. 以降の処理の記述は省略（Apple Store Connectでの操作になる）
