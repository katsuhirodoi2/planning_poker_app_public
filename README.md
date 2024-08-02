## 本レポジトリ（プランニングポーカーアプリ）の利用方法

### 1. Flutterプロジェクトの作成とレポジトリ上のファイルのコピー

1. ローカル端末にて、Flutterプロジェクトを作成する

```
 $ flutter create planning_poker_app

 以下はWeb版のプロジェクトを有効にするための手順
  $ flutter channel stable
  $ flutter upgrade
  $ flutter config --enable-web
  $ cd planning_poker_app
  $ flutter create .
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


### 3. Firebaseとの接続設定

planning_poker_app/lib/main.dart
および
planning_poker_app/web/index.html

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

### 5. AppStoreおよびGoogle Play Storeへの導線設定

1. スクリプト設置サーバーとドメインを用意する（サーバーは一般的なWebホスティングサービスで構わない）

2. スクリプトを設置する

https://qiita.com/katsuhirodoi2/items/08514dfaa199a1d3e974
上記ページにてAppStoreへの導線（ユニバーサルリンク）用スクリプトの例や他の必要な設定について解説しています。

Google Play Storeへの導線（App Links）の設定方法については、今後記事を公開する予定です。

3. コードを編集する

#### 対象ファイル

planning_poker_app/lib/screens/room_screen.dart
および
planning_poker_app/lib/main.dart

#### 編集方法

[スクリプト設置ドメイン]

という文字列を「1で用意したドメイン名」に変更する

### 5. Web版アプリの環境構築とデプロイ

https://firebase.google.com/docs/hosting/frameworks/flutter?hl=ja

を参考に対応する。なお、デプロイ前にプロジェクトルート（planning_poker_app）直下にて、

```
$ flutter build web
```

コマンドの実行が必要と思われる。



### 6. Androidアプリの設定とデプロイ

#### ビルド用設定

1. planning_poker_app/android/app/build.gradle

1-1. pluginsブロックに以下を追加

```
    id 'com.google.gms.google-services'
```

1-2. def系のコードが並んでいる辺りに以下を追加

```
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

1-3. androidブロック内の「namespace」および「applicationId」をFirebaseにAndroidアプリを登録した際のパッケージ名と同じ値にする。

1-4. androidブロック内のbuildTypesブロックの上部辺りに以下を追加

```
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
```

1-5. androidブロック内のbuildTypesブロック内のreleaseブロック内の以下記述を

```
            signingConfig = signingConfigs.debug
```

以下のように変更する（この変更は不要かもしれない（ビルドがうまくいかなかった際に確認するのでも良いと考える））

```
            signingConfig = signingConfigs.release
```

1-6. androidブロック内のbuildTypesブロックに以下を追加（この変更は不要かもしれない（ビルドがうまくいかなかった際に確認するのでも良いと考える））

```
        debug {
            minifyEnabled true
        }
```

2. planning_poker_app/android/build.gradle

ファイル冒頭に以下の追加が必要である模様

```
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0' // 既存の依存関係
        classpath 'com.google.gms:google-services:4.3.14' // Google Services プラグイン
    }
}
```

3. planning_poker_app/android/gradle.properties

ファイルに以下を追加（この変更は不要かもしれない（ビルドがうまくいかなかった際に確認するのでも良いと考える））

```
kotlin.code.style=official
kotlin.incremental=true
android.defaults.buildfeatures.buildconfig=true
android.nonTransitiveRClass=false
android.nonFinalResIds=false
```

4. 署名鍵の作成

4-1. 署名鍵を作成

コマンド例

```
keytool -genkey -v -keystore ~/my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
```

4-2. key.propertiesファイルの作成

ファイルパス
planning_poker_app/android/key.properties

ファイル例

```
storePassword=[4-1で入力したパスワード]
keyPassword=[4-1で入力したパスワード]
keyAlias=[4-1で入力したalias名（my-key-alias等)]
storeFile=[4-1で入力した.jksファイルのフルパス]
```

#### リリース申請時の広告に関するエラー回避

planning_poker_app/android/app/src/main/AndroidManifest.xml

のmanifestタグのすぐ下、applicationタグの前（3行目付近）に以下を追加（広告を使用している場合のみ必要）

```
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />
```

※Firebaseを使用するだけで広告が存在するという判定になるようです。以下の記事を参考に、Firebaseの広告設定を解除することで、意図的に広告を導入してない限り、上記の設定は不要になります。
https://qiita.com/Nkzn/items/326ad03e358b5d3fbafc

#### アプリアイコンおよびランチャーアイコンの作成

1. アイコンの生成
```
$ flutter pub run flutter_launcher_icons:main
```

2. スプラッシュ画像の生成
```
$ flutter pub run flutter_native_splash:create
```

#### ビルドとデプロイ

1. pubspec.yamlのversion表記が、前回appstoreでリリースしたとき？のバージョンより高くなっていることを確認する（例えば、1.0.2+3でいう+3のところが重要である模様）

例

```
version: 1.0.2+6
```

2. Appバンドルの作成

```
プロジェクトルート（planning_poker_app）直下に移動

$ cd planning_poker_app

$ flutter build appbundle --release
```

3. 以後の手順は省略

Google Play Consoleにて作成したAppバンドルをアップロードし、リリース画面にてAppバンドルを選択し、申請をするなどの手順になると思います。

### 7. Appleアプリの設定とデプロイ

#### ビルド用設定

省略

XcodeよりアプリのバンドルIDの設定や、署名設定（Signing & Capabilitiesにて）を行うことになると思います。

#### アプリアイコンおよびランチャーアイコンの作成

「6. Androidアプリの設定とデプロイ」の「アプリアイコンおよびランチャーアイコンの作成」を実施済みであれば不要

#### ビルドとデプロイ

1. プロジェクトルート直下にて、

```
flutter build ios --release
```

コマンドを実行する

2. Xcodeにてアーカイブ処理を行う
  
XcodeのメニューからProduct -> Archiveを選択する。これにより、アーカイブプロセスが開始され、成功すると、Organizerウィンドウが表示される。

3. Xcodeからストアにアップロードする

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

4. 以降の処理の記述は省略（App Store Connectでの操作になる）
